require 'minitest/autorun'
require 'minitest/spec'
require './lib'
require 'json'

describe 'Speccing storage classes' do
  before do
    @store = Store.new
    @msg1 = Message.new(:move, '123-123-123', :tank, 'sausheong', 10, 10, 5)
    @msg2 = Message.new(:move, '123-123-123', :tank, 'sausheong', 10, 11, 5)
    @msg3 = Message.new(:new, '123-123-123', :shot, 'sausheong', 10, 10, 5)
  end
  
  it 'should allow me to add a new object' do
    ptr = Pointer.new(@store)
    ptr.tag @msg1, 'tank'
    ptr.tag @msg2, 'tank'
    
    tanks = ptr.get('tank')
    tanks.must_include @msg1
    tanks.must_include @msg2
  end
  
  it 'should allow me to create convert to JSON' do
    p @msg1.to_json
  end
  
end
   