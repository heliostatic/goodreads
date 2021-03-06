require 'spec_helper'
require 'oauth'

describe 'Client' do
  let(:client)  { Goodreads::Client.new(:api_key => 'SECRET_KEY') }
  before(:each) { Goodreads.reset_configuration }

  describe '#new' do
    it 'requires an argument' do
      expect { Goodreads::Client.new(nil) }.
        to raise_error ArgumentError, "Options hash required."
    end

    it 'requires a hash argument' do
      expect { Goodreads::Client.new('foo') }.
        to raise_error ArgumentError, "Options hash required."
    end
  end

  describe '#book_by_isbn' do
    before { stub_with_key_get('/book/isbn', {:isbn => '0307463745'}, 'book.xml') }

    it 'returns a book by isbn' do
      book = client.book_by_isbn('0307463745')

      book.should respond_to :id
      book.should respond_to :title
    end

    context 'when book does not exist' do
      before do
        stub_request(:get, "http://www.goodreads.com/book/isbn?format=xml&isbn=123456789&key=SECRET_KEY").
          to_return(:status => 404, :body => "", :headers => {}) 
      end

      it 'raises Goodreads::NotFound' do
        expect { client.book_by_isbn('123456789') }.to raise_error Goodreads::NotFound
      end
    end
  end

  describe '#search_books' do
    before { stub_with_key_get('/search/index', {:q => 'Rework'}, 'search_books_by_name.xml') }

    it 'returns book search results' do
      result = client.search_books('Rework')

      result.should be_a Hashie::Mash
      result.should respond_to :query
      result.should respond_to :total_results
      result.should respond_to :results
      result.results.should respond_to :work
      result.query.should eq 'Rework'
      result.results.work.size.should eq 3
      result.results.work.first.id.should eq 6928276
    end
  end

  describe '#book' do
    before { stub_with_key_get('/book/show', {:id => '6732019'}, 'book.xml') }

    it 'returns a book by goodreads id' do
      expect { client.book('6732019') }.not_to raise_error
    end
  end

  describe '#book_by_title' do
    before { stub_with_key_get('/book/title', {:title => 'Rework'}, 'book.xml') }

    it 'returns a book by title' do
      expect { client.book_by_title('Rework') }.not_to raise_error
    end
  end

  describe '#recent_reviews' do
    before { stub_with_key_get('/review/recent_reviews', {}, 'recent_reviews.xml') }

    it 'returns recent reviews' do
      reviews = client.recent_reviews

      reviews.should be_an Array
      reviews.should_not be_empty
      reviews.first.should respond_to :id
    end

    context 'with :skip_cropped => true' do
      before { stub_with_key_get('/review/recent_reviews', {}, 'recent_reviews.xml') }
  
      it 'returns only full reviews' do
        reviews = client.recent_reviews(:skip_cropped => true)
        reviews.should be_an Array
        reviews.should_not be_empty
      end
    end
  end

  describe '#review' do
    before { stub_with_key_get('/review/show', {:id => '166204831'}, 'review.xml') }

    it 'returns review details' do
      review = client.review('166204831')

      review.should be_a Hashie::Mash
      review.id.should eq '166204831'
    end

    context 'when review does not exist' do
      before do
        stub_request(:get, "http://www.goodreads.com/review/show?format=xml&id=12345&key=SECRET_KEY").
          to_return(:status => 404, :body => "", :headers => {})
      end

      it 'raises Goodreads::NotFound' do
        expect { client.review('12345') }.to raise_error Goodreads::NotFound
      end
    end
  end

  describe '#author' do
    before { stub_with_key_get('/author/show', {:id => '18541'}, 'author.xml') }

    it 'returns author details' do
      author = client.author('18541')

      author.should be_a Hashie::Mash
      author.id.should eq '18541'
      author.name.should eq "Tim O'Reilly"
      author.link.should eq 'http://www.goodreads.com/author/show/18541.Tim_O_Reilly'
      author.fans_count.should eq 109
      author.image_url.should eq 'http://photo.goodreads.com/authors/1199698411p5/18541.jpg'
      author.small_image_url.should eq 'http://photo.goodreads.com/authors/1199698411p2/18541.jpg'
      author.about.should eq '' 
      author.influences.should eq ''
      author.works_count.should eq '34'
      author.gender.should eq 'male'
      author.hometown.should eq 'Cork'
      author.born_at.should eq '1954/06/06'
      author.died_at.should be_nil
    end

    context 'when author does not exist' do
      before do
        stub_request(:get, "http://www.goodreads.com/author/show?format=xml&id=12345&key=SECRET_KEY").
          to_return(:status => 404, :body => "", :headers => {})
      end

      it 'raises Goodreads::NotFound' do
        expect { client.author('12345') }.to raise_error Goodreads::NotFound
      end
    end
  end

  describe '#author_by_name' do
    before do
      stub_with_key_get('/api/author_url', {:id => 'Orson Scott Card'}, 'author_by_name.xml')
    end

    it 'returns author details' do
      author = client.author_by_name('Orson Scott Card')

      author.should be_a Hashie::Mash
      author.id.should eq   '589'
      author.name.should eq 'Orson Scott Card'
      author.link.should eq 'http://www.goodreads.com/author/show/589.Orson_Scott_Card?utm_medium=api&utm_source=author_link'
    end
  end

  describe '#books_by_author' do
    before { stub_with_key_get('/author/list', {:id => '18541'}, 'books_by_author.xml') }

    it 'returns list of books for a specified author' do
      list = client.books_by_author('18541')

      list.should respond_to :start
      list.should respond_to :end
      list.should respond_to :total
      list.should respond_to :books

      list.start.should eq 1
      list.end.should eq 30
      list.total.should eq 50
      list.books.length.should eq 30
      list.books.first.id.should eq 104744
      list.books.first.title.strip.should eq 'The Cathedral & the Bazaar: Musings on Linux and Open Source by an Accidental Revolutionary'
    end
  end

  describe '#series_by_author' do
    before { stub_with_key_get('/series/list', {:id => '227840'}, 'series_by_author.xml') }

    it 'returns list of series for a specified author' do
      list = client.series_by_author('227840')

      list.length.should eq 13
      list.first.series.title.strip.should eq 'The Ballet Family'
      list.first.series.primary_work_count.should eq "2"
      list.first.series.series_works_count.should eq "2"
    end
  end

  describe '#books_by_series' do
    before { stub_with_key_get('/series/show', {:id => '52928'}, 'books_by_series.xml') }

    it 'returns list of books for a specified author' do
      list = client.books_by_series('52928')

      list.should respond_to :book_count
      list.should respond_to :series_title
      list.should respond_to :series
      list.should respond_to :titles

      list.book_count.should eq "3"
      list.series_title.strip.should eq 'Matched'
      list.titles.should eq ["Matched (Matched, #1)", "Crossed (Matched, #2)", "Reached (Matched, #3)", "Matched Trilogy Box Set"]
      list.series.length.should eq 4
      list.series.first.id.should eq "206283"
      list.series.first.work.best_book.title.strip.should eq "Matched (Matched, #1)"
    end
  end

  describe '#user' do
    before { stub_with_key_get('/user/show', {:id => '878044'}, 'user.xml') }

    it 'returns user details' do
      user = client.user('878044')

      user.should be_a Hashie::Mash
      user.id.should eq '878044'
      user.name.should eq 'Jan'
      user.user_name.should eq 'janmt'
    end

    context 'when user does not exist' do
      before do
        stub_request(:get, "http://www.goodreads.com/user/show?format=xml&id=12345&key=SECRET_KEY").
          to_return(:status => 404, :body => "", :headers => {})
      end

      it 'raises Goodreads::NotFound' do
        expect { client.user('12345') }.to raise_error Goodreads::NotFound
      end
    end
  end

  describe '#friends' do
    before { client.stub(:oauth_request).and_return(Hash.from_xml(fixture('friends.xml'))['GoodreadsResponse']) }

    it 'returns friend details' do
      friends = client.friends('878044')

      friends.should be_an_instance_of Hashie::Mash
      friends.should respond_to :user
      friends.user.size.should eq friends.end.to_i
      friends.user.first.should respond_to :name
    end
  end

  describe '#shelf' do
    it "returns list of books for a user's specified shelf" do
      stub_with_key_get('/review/list/1.xml', {:shelf => 'to-read', :v => '2'}, 'to-read.xml')

      shelf = client.shelf('1', 'to-read')

      shelf.should respond_to :start
      shelf.should respond_to :end
      shelf.should respond_to :total
      shelf.should respond_to :books

      shelf.start.should eq 1
      shelf.end.should eq 20
      shelf.total.should eq 40
      shelf.books.length.should eq 20
      shelf.books.first.id.should eq '45590939'
      shelf.books.first.book.title.strip.should eq 'The Demon-Haunted World: Science as a Candle in the Dark'
    end

    it "paginates book lists from a user's shelf" do
      stub_with_key_get('/review/list/1.xml', {:shelf => 'to-read', :v => '2', :page => '2'}, 'to-read-p2.xml')

      shelf = client.shelf('1', 'to-read', :page => 2)

      shelf.start.should eq 21
      shelf.end.should eq 40
      shelf.total.should eq 40
      shelf.books.length.should eq 20
      shelf.books.first.id.should eq '107804211'
      shelf.books.first.book.title.should match /Your Money or Your Life/
    end

    it "returns an empty array when shelf is empty" do
      stub_with_key_get('/review/list/1.xml', {:shelf => 'to-read', :v => '2'}, 'empty.xml')

      shelf = client.shelf('1', 'to-read')

      shelf.start.should eq 0
      shelf.end.should eq 0
      shelf.total.should eq 0
      shelf.books.length.should eq 0
    end
  end

  describe '#list_shelves' do
    it 'returns list of shelves for a specified user' do  
      stub_with_key_get('/shelf/list.xml', {:user_id => '66726'}, 'list_shelves.xml')

      shelves = client.list_shelves(66726)

      shelves.should respond_to :start
      shelves.should respond_to :end
      shelves.should respond_to :total
      shelves.should respond_to :names
      shelves.should respond_to :shelves

      shelves.start.should eq 1
      shelves.end.should eq 6
      shelves.total.should eq 6
      shelves.names.should eq ["read", "currently-reading", "to-read", "to-be-processed", "owned", "want-to-own"]
      shelves.shelves.last.name.should eq 'want-to-own'
    end
  end

  describe '#add_book_to_shelf' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:post, "http://www.goodreads.com/shelf/add_to_shelf.xml?book_id=1157446&name=to-read").
        to_return(:status => 200, :body => fixture('add_book_to_shelf.xml'), :headers => {})
    end

    it 'returns success after adding book to a shelf' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
        data = client.add_book_to_shelf(1157446, 'to-read')

        data.body.should match('<name>to-read</name>')
        data.body.should match('<position type="integer">1</position>')
    end
  end

  describe '#add_books_to_shelves' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:post, "http://www.goodreads.com/shelf/add_books_to_shelves.xml?bookids=1157446,133376,17311580&shelves=to-read,want-to-own").
        to_return(:status => 200, :body => fixture('add_books_to_shelves.xml'), :headers => {})
    end

    it 'returns success after adding books to shelves' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
        data = client.add_books_to_shelves("1157446,133376,17311580", 'to-read,want-to-own')

        data.body.should match('<result>ok</result>')
        data.body.should match('shelf_add_books_to_shelves')
    end
  end

  describe '#remove_book_from_shelf' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:post, "http://www.goodreads.com/shelf/add_to_shelf.xml?book_id=1157446&name=to-read").
        to_return(:status => 200, :body => fixture('remove_book_from_shelf.xml'), :headers => {})
    end

    it 'returns empty message after removing book from a shelf' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
        data = client.add_book_to_shelf(1157446, 'to-read')

        data.body.should eq nil
    end
  end

  describe '#user_id' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:get, "http://www.goodreads.com/api/auth_user").
        to_return(:status => 200, :body => fixture('oauth_response.xml'), :headers => {})
    end

    it 'returns id of the user with oauth authentication' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
      client.user_id.should eq '2003928'
    end
  end

  describe '#group' do
    before { stub_with_key_get('/group/show', {:id => '1'}, 'group.xml') }

    it "returns group details" do
      group = client.group('1')
    
      group.should be_a Hashie::Mash
      group.id.should eq '1'
      group.title.should eq 'Goodreads Feedback'
      group.access.should eq 'public'
      group.location.should eq ''
      group.category.should eq 'Business'
      group.subcategory.should eq 'Companies'
      group.group_users_count.should eq '10335'
    end
  end

  describe '#group_list' do
    before { stub_with_key_get('/group/list', {:id => '1', :sort => 'my_activity'}, 'group_list.xml') }

    it "returns groups a given user is a member of" do
      group_list = client.group_list('1')

      group_list.should be_a Hashie::Mash
      group_list.total.should eq '107'
      group_list.group.count.should eq 50
      group_list.group[0].id.should eq '1'
      group_list.group[0].title.should eq 'Goodreads Feedback'
      group_list.group[1].id.should eq '220'
      group_list.group[2].users_count.should eq '530'
    end
  end

  describe '#owned_books' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:get, "http://www.goodreads.com/owned_books/user?id=6921131").
        to_return(:status => 200, :body => fixture('owned_books.xml'), :headers => {})
    end

    it 'returns list of books the specified user owns' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
      books = client.owned_books(6921131)

      books.size.should eq 30
      books.first.current_owner_id.should eq 6921131
      books.first.book.isbn13.should eq "9781741856255"
    end
  end  

  describe '#add_ownership' do
    let(:consumer) { OAuth::Consumer.new('API_KEY', 'SECRET_KEY', :site => 'http://www.goodreads.com') }
    let(:token)    { OAuth::AccessToken.new(consumer, 'ACCESS_TOKEN', 'ACCESS_SECRET') }

    before do
      stub_request(:post, "http://www.goodreads.com/owned_books.xml?owned_book%5Bbook_id%5D=1157446").
        to_return(:status => 200, :body => fixture('add_ownership.xml'), :headers => {})
    end

    it 'returns success after adding the book' do
      client = Goodreads::Client.new(:api_key => 'SECRET_KEY', :oauth_token => token)
        data = client.add_ownership(1157446)

        data.body.should match('<current-owner-id type="integer">6961231</current-owner-id>')
        data.body.should match('<book-id type="integer">1157446</book-id>')
    end
  end

end
