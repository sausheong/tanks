require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/benchmark'
require './lib'


describe 'Benchmarking lib' do
  before do
    @store = Store.new
    @msg1 = Message.new(:move, '123-123-123', :tank, 'sausheong', 10, 10, 5)
    @msg2 = Message.new(:move, '123-123-123', :tank, 'sausheong', 10, 11, 5)
    @msg3 = Message.new(:new, '123-123-123', :shot, 'sausheong', 10, 10, 5)
    @ptr = Pointer.new(@store)
    tags = %w(apples oranges peaches bananas grapes cherries strawberries persimmons)
    10000.times do 
      tag = tags[rand(8)] 
      @ptr.tag(@msg1, tag)
    end
  end
   
  bench_range { bench_exp 1, 1000 }
  bench_performance_linear "add object", 0.999 do |n|
    n.times do
      @ptr.tag @msg1, 'apples'
    end
  end

  bench_performance_linear "get objects", 0.999 do |n|
    n.times do
      @ptr.get 'apples'      
    end
  end
  
  
    
end