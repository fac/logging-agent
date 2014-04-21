require 'spec_helper'

describe LogAgent::Filter::MysqlSlow do
  let(:sink) { mock('MySinkObject', :<< => nil) }
  let(:filter) { LogAgent::Filter::MysqlSlow.new sink }

  it 'should be created with new <sink>' do
    filter.sink.should == [sink]
  end

  describe 'parsing' do
    load_entries!('mysql_slow_entries')

    let(:events)  { [] }
    before { sink.stub(:<<) { |e| events << e } }

    it "should emit each uncommented line directly" do
      filter << LogAgent::Event.new(:message => "foo;")
      filter << LogAgent::Event.new(:message => "bar;")
      filter << LogAgent::Event.new(:message => "baz;")
      events.map(&:message).should == ['foo;', 'bar;', 'baz;']
    end

    it "should break queries on a semicolon rather than newline, up to the limit"

    it "should not pass through any commented lines" do
      filter << LogAgent::Event.new(:message => "foo;")
      filter << LogAgent::Event.new(:message => "# stuff here")
      filter << LogAgent::Event.new(:message => "# more stuff")
      filter << LogAgent::Event.new(:message => "bar;")
      filter << LogAgent::Event.new(:message => "# a comment")
      filter << LogAgent::Event.new(:message => "baz;")

      events.map(&:message).should == ['foo;', 'bar;', 'baz;']
    end

    describe "limiting query length" do
      it "should default the limit to 1024 bytes" do
        filter.limit.should == 1024
      end

      it "should truncate lines to the limit parameter, if they exceed it" do
        filter = LogAgent::Filter::MysqlSlow.new(sink, :limit => 10)

        filter << LogAgent::Event.new(:message => "foo;")
        filter << LogAgent::Event.new(:message => "bar is very long so we expect it to be truncated;")
        filter << LogAgent::Event.new(:message => "baz;")
        events.map(&:message).should == ["foo;", 'bar is ver', 'baz;']
      end

      it "should note the truncated lines as such, and record their original length" do
        filter = LogAgent::Filter::MysqlSlow.new(sink, :limit => 10)
        filter << LogAgent::Event.new(:message => "bar is very long so we expect it to be truncated;")
        event = events.first
        event.fields['truncated'].should be_true
        event.fields['original_length'].should == 49
      end

      it "should not skip the next commented line immediately following a truncated query line"
    end

    describe "Parsing the timestamp comment" do
      let(:upstream_timestamp) { mock("Upstream Timestamp") }

      it "should, by default, not mess with the upstream timestamp" do
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;", :timestamp => upstream_timestamp)
        events.first.timestamp.should == upstream_timestamp
      end

      it "should associate a UTC Timestamp comment with the subsequent query" do
        filter << LogAgent::Event.new(:message => "# Time: 140331 15:05:29")
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        events.size.should == 1
        events.first.timestamp.should == Time.utc(2014, 03, 31, 14, 05, 29)
      end


      it "should map the timestamp to all subsequent queries (since slow_query_log_timestamp_always is an option) until the next timestamp string" do
        filter << LogAgent::Event.new(:message => "# Time: 140331 15:05:29")
        filter << LogAgent::Event.new(:message => "SELECT things FROM here;")
        filter << LogAgent::Event.new(:message => "SELECT others FROM there;", :timestamp => upstream_timestamp)
        filter << LogAgent::Event.new(:message => "# Time: 140331 15:06:30")
        filter << LogAgent::Event.new(:message => "SELECT things FROM here;")

        events.size.should == 3
        events[0].timestamp.should == Time.utc(2014, 03, 31, 14, 05, 29)
        events[1].timestamp.should == Time.utc(2014, 03, 31, 14, 05, 29)
        events[2].timestamp.should == Time.utc(2014, 03, 31, 14, 06, 30)
      end

      it "should associate the upstream timestamp with a query if it can't parse the comment" do
        filter << LogAgent::Event.new(:message => "# Time: such time so ticky")
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;", :timestamp => upstream_timestamp)
        events.first.timestamp.should == upstream_timestamp
      end

    end

    describe "query timing / row-count data parsing" do

      it "should not include the information by default" do
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        events.first.fields['query'].should be_nil
      end

      it "should attach the data to the next request" do
        filter << LogAgent::Event.new(:message => "# Query_time: 100  Lock_time: 50  Rows_sent: 20  Rows_examined: 322814")
        filter << LogAgent::Event.new(:message => "SELECT name FROM animals WHERE noise = 'moo';")
        events.first.fields['query']['time'].should == 100
        events.first.fields['query']['lock_time'].should == 50
        events.first.fields['query']['rows_sent'].should == 20
        events.first.fields['query']['rows_examined'].should == 322814

      end

      it "should not attach the same data to more than one request" do
        filter << LogAgent::Event.new(:message => "# Query_time: 3  Lock_time: 0  Rows_sent: 2  Rows_examined: 322814")
        filter << LogAgent::Event.new(:message => "SELECT things FROM here;")
        filter << LogAgent::Event.new(:message => "SELECT more FROM there;")
        events.first.fields['query']['time'].should == 3
        events.last.fields['query'].should be_nil
      end

    end

    describe "connection metadata parsing" do
      it "should not associate any data by default" do
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        events.first.fields['connection'].should be_nil
      end

      it "should attach the same data to subsequent requests, until the next comment" do
        filter << LogAgent::Event.new(:message => "# User@Host: app[sys_app] @  [4.4.4.4]")
        filter << LogAgent::Event.new(:message => "SELECT things FROM here;")
        filter << LogAgent::Event.new(:message => "SELECT more FROM there;")
        filter << LogAgent::Event.new(:message => "# User@Host: john[john] @  [6.6.6.6]")
        filter << LogAgent::Event.new(:message => "SELECT more FROM there;")
        events[0].fields['connection']['user'].should == 'app'
        events[0].fields['connection']['system_user'].should == 'sys_app'
        events[0].fields['connection']['host'].should == '4.4.4.4'

        events[1].fields['connection']['user'].should == 'app'
        events[1].fields['connection']['system_user'].should == 'sys_app'
        events[1].fields['connection']['host'].should == '4.4.4.4'

        events[2].fields['connection']['user'].should == 'john'
        events[2].fields['connection']['system_user'].should == 'john'
        events[2].fields['connection']['host'].should == '6.6.6.6'
      end
    end

    describe "database use statement parsing" do
      it "should not attach the database by default" do
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        events.first.fields['database'].should be_nil
      end

      it "should drop use statements as metadata" do
        filter << LogAgent::Event.new(:message => "use some_database;")
        events.size.should == 0
      end

      it "should attach the database line if a use statement has been encountered" do
        filter << LogAgent::Event.new(:message => "use database_a;")
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        filter << LogAgent::Event.new(:message => "USE database_b;")
        filter << LogAgent::Event.new(:message => "SELECT things from HERE;")
        events.map { |e| e.fields['database'] }.should == ['database_a', 'database_a', 'database_b']
      end
    end

    describe "query fingerprint calculation" do

      it "should attach the fingerprint of all queries" do
        filter << LogAgent::Event.new(:message => "SELECT  companies.*, COUNT(notifications.id) notifications_count FROM `companies` INNER JOIN `subscriptions` ON `subscriptions`.`company_id` = `companies`.`id` INNER JOIN `account_managers` ON `companies`.`account_manager_id` = `account_managers`.`id` LEFT JOIN notifications ON (notifications.company_id = companies.id AND notifications.dismissed_at IS NULL ) WHERE `account_managers`.`accountancy_practice_id` = 11789 AND (subscriptions.status <> 'Cancelled') AND (subscriptions.status <> 'Suspended') AND (subscriptions.free_trial_expires_on IS NULL OR subscriptions.free_trial_expires_on >= '2014-04-21') GROUP BY companies.id ORDER BY companies.name ASC LIMIT 30 OFFSET 0;")
        events.first.fields['fingerprint'].should == Digest::MD5.hexdigest("select companies.*, count(notifications.id) notifications_count from `companies` inner join `subscriptions` on `subscriptions`.`company_id` = `companies`.`id` inner join `account_managers` on `companies`.`account_manager_id` = `account_managers`.`id` left join notifications on (notifications.company_id = companies.id and notifications.dismissed_at is ? ) where `account_managers`.`accountancy_practice_id` = ? and (subscriptions.status <> ?) and (subscriptions.status <> ?) and (subscriptions.free_trial_expires_on is ? or subscriptions.free_trial_expires_on >= ?) group by companies.id order by companies.name limit ?")
      end

      it "should lowercase the query" do
        filter.fingerprint("SELECT foo FROM bar;").should == 'select foo from bar'
      end

      it "should replace string literals with placeholders" do
        filter.fingerprint("SELECT col, 'foo' FROM somewhere;").should == 'select col, ? from somewhere'
        filter.fingerprint("SELECT col, \"bar\" FROM somewhere;").should == 'select col, ? from somewhere'
        filter.fingerprint("SELECT col, 2 FROM somewhere;").should == 'select col, ? from somewhere'
        filter.fingerprint("SELECT col FROM somewhere where id=5 and number  = '26';").should == 'select col from somewhere where id=? and number = ?'
      end

      it "should replace excessive spaces with a single space" do
        filter.fingerprint("    select  foo      from bar;").should == 'select foo from bar'
        filter.fingerprint("select  foo \n     from bar ;   ").should == 'select foo from bar'
      end

      it "should remove any comment blocks" do
        filter.fingerprint("    select /* thing!! \n */ foo      from bar;").should == 'select foo from bar'
      end

      it "should replace IN (1,2,'3') with in(?+)" do
        filter.fingerprint("select  foo where value in (1,2, '3');").should == 'select foo where value in(?+)'
      end

      it "should handle the pt-fingerprint test cases" do
        filter.fingerprint("select * from db.tbl where id=1 or foo='bar';").should == "select * from db.tbl where id=? or foo=?"
        filter.fingerprint("select col from db.tbl where id in (1, 2, 3);").should == "select col from db.tbl where id in(?+)"
        filter.fingerprint("DELETE FROM t1
WHERE s11 > ANY
 (SELECT COUNT(*) /* no hint */ FROM t2
  WHERE NOT EXISTS
   (SELECT * FROM t3
    WHERE ROW(5*t2.s1,77)=
     (SELECT 50,11*s1 FROM t4 UNION SELECT 50,77 FROM
      (SELECT * FROM t5) AS t5)));").should == "delete from t? where s? > any (select count(*) from t? where not exists (select * from t? where row(?*t?s?,?)= (select ?,?*s? from t? union select ?,? from (select * from t?) as t?)))"
        #filter.fingerprint("SELECT c FROM db.fbc5e685a5d3d45aa1d0347fdb7c4d35_temp where id=1").should == "select c from db.?_temp where id=?"
        #filter.fingerprint("SELECT c FROM db.temp_fbc5e685a5d3d45aa1d0347fdb7c4d35 where id=1").should == "select c from db.temp_? where id=?"
        #filter.fingerprint("SELECT c FROM db.catch22 WHERE id is null").should == "select c from db.catch22 where id is ?"
      end

      describe "percona toolkit QueryReviewer test cases" do
        # http://bazaar.launchpad.net/~percona-toolkit-dev/percona-toolkit/pt-fingerprint/view/head:/t/lib/QueryRewriter.t#L57
        # it "handle complex comments" do
        #   filter.fingerprint(%[UPDATE groups_search SET  charter = '   -------3\'\' XXXXXXXXX.\n    \n    -----------------------------------------------------', show_in_list = 'Y' WHERE group_id='aaaaaaaa']).should ==
        #     "update groups_search set charter = ?, show_in_list = ? where group_id=?"
        # end

        it "should fingerprint all mysqldump SELECTs together" do
          filter.fingerprint("SELECT /*!40001 SQL_NO_CACHE */ * FROM `film`").should ==
            'mysqldump'
        end

        it "should fingerprint stored procedure calls specially" do
          filter.fingerprint("CALL foo(1, 2, 3)").should == 'call foo'
        end

        it "should fingerprint admin commands as themselves" do
          filter.fingerprint("administrator command: Init DB").should ==
            "administrator command: Init DB"
        end

        it "should fingerprint mk-table-checksum queries together" do
          filter.fingerprint(<<-SQL).should == 'percona-toolkit'
            REPLACE /*foo.bar:3/3*/ INTO checksum.checksum (db, tbl,
              chunk, boundaries, this_cnt, this_crc) SELECT 'foo', 'bar',
              2 AS chunk_num, '`id` >= 2166633', COUNT(*) AS cnt,
              LOWER(CONV(BIT_XOR(CAST(CRC32(CONCAT_WS('#', `id`, `created_by`,
              `created_date`, `updated_by`, `updated_date`, `ppc_provider`,
              `account_name`, `provider_account_id`, `campaign_name`,
              `provider_campaign_id`, `adgroup_name`, `provider_adgroup_id`,
              `provider_keyword_id`, `provider_ad_id`, `foo`, `reason`,
              `foo_bar_bazz_id`, `foo_bar_baz`, CONCAT(ISNULL(`created_by`),
              ISNULL(`created_date`), ISNULL(`updated_by`), ISNULL(`updated_date`),
              ISNULL(`ppc_provider`), ISNULL(`account_name`),
              ISNULL(`provider_account_id`), ISNULL(`campaign_name`),
              ISNULL(`provider_campaign_id`), ISNULL(`adgroup_name`),
              ISNULL(`provider_adgroup_id`), ISNULL(`provider_keyword_id`),
              ISNULL(`provider_ad_id`), ISNULL(`foo`), ISNULL(`reason`),
              ISNULL(`foo_base_foo_id`), ISNULL(`fooe_foo_id`)))) AS UNSIGNED)), 10,
              16)) AS crc FROM `foo`.`bar` USE INDEX (`PRIMARY`) WHERE
              (`id` >= 2166633);
          SQL
        end

        it "should remove the identifier from use" do
          filter.fingerprint("use `foo`").should == 'use ?'
        end

        it "should remove one-line comments from fingerprints" do
          filter.fingerprint("select \n--bar\n foo").should == 'select foo'
        end

        it "should remove one-line comments in fingerprint without mushing things together" do
          filter.fingerprint("select foo--bar\nfoo").should == 'select foo foo'
        end

        it "should remove one-line EOL comments in fingerprints" do
          filter.fingerprint("select foo -- bar\n").should == 'select foo'
        end

        xit "should normalize commas and equals" do
          filter.fingerprint("select a,b ,c , d from tbl where a=5 or a = 5 or a=5 or a =5").should ==
            "select a, b, c, d from tbl where a=? or a=? or a=? or a=?"
        end

        it "should handle bug from perlmonks thread 728718" do
          filter.fingerprint("select null, 5.001, 5001. from foo").should ==
            "select ?, ?, ? from foo"
        end

        it "should handle quoted strings" do
          filter.fingerprint("select 'hello', '\nhello\n', \"hello\", '\\'' from foo").should ==
            "select ?, ?, ?, ? from foo"
        end

        it "should handle trailing newline" do
          filter.fingerprint("select 'hello'\n").should == "select ?"
        end

        it "should handle all quoted strings" do
          filter.fingerprint("select '\\\\' from foo").should == "select '\\ from foo"
        end

        it "should collapse whitespace" do
          filter.fingerprint('select    foo').should == 'select foo'
        end

        it "should lowercase and replace integer" do
          filter.fingerprint("SELECT * from foo where a = 5").should ==
            "select * from foo where a = ?"
        end

        it "should replace floats" do
          filter.fingerprint('select 0e0, +6e-30, -6.00 from foo where a = 5.5 or b=0.5 or c=.5').should ==
            'select ?, ?, ? from foo where a = ? or b=? or c=?'
        end

        it "should replace hex/bit"do
          filter.fingerprint("select 0x0, x'123', 0b1010, b'10101' from foo").should ==
            'select ?, ?, ?, ? from foo'
        end

        it "shoudl collapse more whitespace" do
          filter.fingerprint(" select  * from\nfoo where a = 5").should ==
            'select * from foo where a = ?'
        end

        it "should fingerprint IN lists" do
          filter.fingerprint("select * from foo where a in (5) and b in (5, 8,9 ,9 , 10)").should ==
            'select * from foo where a in(?+) and b in(?+)'
        end


        it "should replace numeric table names" do
          filter.fingerprint("select foo_1 from foo_2_3").should ==
            'select foo_? from foo_?_?'
        end

        it "should handle a string that needs no changes" do
          filter.fingerprint("insert into abtemp.coxed select foo.bar from foo").should ==
            'insert into abtemp.coxed select foo.bar from foo'
        end


        it "should handle VALUES lists" do
          filter.fingerprint('insert into foo(a, b, c) values(2, 4, 5)').should ==
            'insert into foo(a, b, c) values(?+)'
        end


        it "should handle VALUEs lists with multiple ()" do
          filter.fingerprint('insert into foo(a, b, c) values(2, 4, 5) , (2,4,5)').should ==
            'insert into foo(a, b, c) values(?+)'
        end


        it "should handle VALUES lists with VALUE()" do
          filter.fingerprint('insert into foo(a, b, c) value(2, 4, 5)').should ==
            'insert into foo(a, b, c) value(?+)'
        end


        it "should handle limit alone" do
          filter.fingerprint('select * from foo limit 5').should ==
            'select * from foo limit ?'
        end


        it "should handle limit with comma offset" do
          filter.fingerprint('select * from foo limit 5, 10').should ==
            'select * from foo limit ?'
        end

        it "should handle limit with offset" do
          filter.fingerprint('select * from foo limit 5 offset 10').should ==
            'select * from foo limit ?'
        end

        it "should union fingerprints together" do
          filter.fingerprint('select 1 union select 2 union select 4').should ==
            'select ? /*repeat union*/'
        end

        it "should union all fingerprints together" do
          filter.fingerprint('select 1 union all select 2 union all select 4').should ==
            'select ? /*repeat union all*/'
        end

        it "should union all fingerprints together (2)" do
          filter.fingerprint("
            select * from (select 1 union all select 2 union all select 4) as x
            join (select 2 union select 2 union select 3) as y
          ").should == "select * from (select ? /*repeat union all*/) as x join (select ? /*repeat union*/) as y"
        end

        it "should remove ASC from ORDER BY" do
          # Issue 1030: Fingerprint can remove ORDER BY ASC
         filter.fingerprint("select c from t where i=1 order by c asc").should ==
           "select c from t where i=? order by c"
        end


        it "should remove only ASC from ORDER BY" do
          filter.fingerprint("select * from t where i=1 order by a, b ASC, d DESC, e asc").should ==
            "select * from t where i=? order by a, b, d desc, e"
        end

        it "should remove ASC from spacey order by" do
          filter.fingerprint(
            "select * from t where i=1      order            by
                a,  b          ASC, d    DESC,

                             e asc",
           ).should ==  "select * from t where i=? order by a, b, d desc, e"
        end


        it "should fingerprint LOAD DATA INFILE" do
          filter.fingerprint("LOAD DATA INFILE '/tmp/foo.txt' INTO db.tbl").should ==
            "load data infile ? into db.tbl"
        end
      end

    end

  end
end
