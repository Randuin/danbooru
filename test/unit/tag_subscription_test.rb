require File.dirname(__FILE__) + '/../test_helper'

class TagSubscriptionTest < ActiveSupport::TestCase
  context "A tag subscription" do
    should "find the union of all posts for each tag in its tag query" do
      posts = []
      user = Factory.create(:user)
      posts << Factory.create(:post, :tag_string => "aaa")
      posts << Factory.create(:post, :tag_string => "bbb")
      posts << Factory.create(:post, :tag_string => "ccc")
      posts << Factory.create(:post, :tag_string => "ddd")
      sub_1 = Factory.create(:tag_subscription, :tag_query => "aaa bbb", :owner => user, :name => "zzz")
      sub_2 = Factory.create(:tag_subscription, :tag_query => "ccc", :owner => user, :name => "yyy")
      assert_equal([posts[1].id, posts[0].id], TagSubscription.find_posts(user.id, "zzz").map(&:id))
      assert_equal([posts[2].id, posts[1].id, posts[0].id], TagSubscription.find_posts(user.id).map(&:id))
    end
    
    should "cache its tag query results" do
      posts = []
      user = Factory.create(:user)
      posts << Factory.create(:post, :tag_string => "aaa")
      posts << Factory.create(:post, :tag_string => "bbb")
      posts << Factory.create(:post, :tag_string => "ccc")
      sub = Factory.create(:tag_subscription, :tag_query => "aaa bbb", :owner => user, :name => "zzz")
      assert_equal("#{posts[1].id},#{posts[0].id}", sub.post_ids)
    end
    
    should "find posts based on its cached post ids" do
      user = Factory.create(:user)
      subs = []
      subs << Factory.create(:tag_subscription, :tag_query => "aaa", :owner => user, :name => "zzz")
      subs << Factory.create(:tag_subscription, :tag_query => "bbb", :owner => user, :name => "yyy")
      assert_equal([], TagSubscription.find_posts(user.id))
      assert_equal([], TagSubscription.find_posts(user.id, "zzz"))
      assert_equal([], TagSubscription.find_posts(user.id, "yyy"))
      posts = []
      posts << Factory.create(:post, :tag_string => "aaa")
      posts << Factory.create(:post, :tag_string => "bbb")
      posts << Factory.create(:post, :tag_string => "ccc")
      subs.each {|x| x.process; x.save}
      assert_equal([posts[1].id, posts[0].id], TagSubscription.find_posts(user.id).map(&:id))
      assert_equal([posts[0].id], TagSubscription.find_posts(user.id, "zzz").map(&:id))
      assert_equal([posts[1].id], TagSubscription.find_posts(user.id, "yyy").map(&:id))
    end
  end

  context "A tag subscription manager" do
    should "process all active tag subscriptions" do
      users = []
      users << Factory.create(:user)
      users << Factory.create(:user)
      posts = []
      posts << Factory.create(:post, :tag_string => "aaa")
      posts << Factory.create(:post, :tag_string => "bbb")
      posts << Factory.create(:post, :tag_string => "ccc")
      subscriptions = []
      subscriptions << Factory.create(:tag_subscription, :tag_query => "aaa", :owner => users[0])
      subscriptions << Factory.create(:tag_subscription, :tag_query => "bbb", :owner => users[1])
      TagSubscription.process_all
      subscriptions.each {|x| x.reload}
      assert_equal("#{posts[0].id}", subscriptions[0].post_ids)
      assert_equal("#{posts[1].id}", subscriptions[1].post_ids)
    end
  end
end