require 'rubygems'
require 'sequel'
require '../lib/dbstruct'
require 'logger'

class AnObject 
  include DBStruct
  @non_persisted_field
  attr_accessor :non_persisted_field
  
  def initialize(*args)
    @non_persisted_field = args[0]
    
  end
  
  def return_value_from_field
    return @non_persisted_field
  end
end

class CreateDb < Sequel::Migration
  def up
    create_table :person do
      primary_key :pkid
      text :name
      float :amount
      integer :age
    end
  end
end


class DBStruct_spec
  DB = Sequel.sqlite '', :logger => [Logger.new($stdout)]
  CreateDb.apply(DB,:up)
  AnObject.bind_table(DB,:person)

  def self.create_test_object
  r = AnObject.template
  r.name = 'Donald'
  r.amount = 10.1
  r.age = 77
  return r
end

  
  context "Create empty object and access fields" do
    setup do
      
    end
    
    specify "All fields should have accesors based on table names" do
      r = DBStruct_spec.create_test_object
      
      r.name.should == 'Donald'
      r.amount.should == 10.1
      r.age.should == 77
    end
    
    specify "should raise error when accessing field that doesn't exist in database or object" do
      r = AnObject.template
      lambda {r.field_does_nt_exist}.should raise_error
    end
    
    specify "should be able to accesses transient (non persisted) values" do
      r = AnObject.template
      r.non_persisted_field = 'BOO'
      r.non_persisted_field.should == 'BOO'
    end
    
    specify "should be able to pass variables to object constructor (initialize)" do
      r = AnObject.template('BOO')
      r.non_persisted_field.should == 'BOO'
    end
    
    specify "should be able to call ordinary method on persisted object" do
      r = AnObject.template("BOO")
      r.return_value_from_field.should == "BOO"
    end
  end
  
  
  context "Use instance to perform insert, read, update and delete" do
    setup do
    end
    
    specify "should be able to insert and read object" do
      i = DBStruct_spec.create_test_object
      
      lambda {i.insert(DB)}.should_not raise_error
      from_db = AnObject.find(DB,{:age => 77}).first
      from_db.name == i.name.should 
      from_db.amount == i.amount.should 
      from_db.age == i.age.should
      
      i.amount = 12.1
      i.update(DB)
      from_db = AnObject.find(DB,{:age => 77}).first
      from_db.name == i.name.should 
      from_db.amount == i.amount.should 
      from_db.age == i.age.should
      
      lambda {AnObject.delete!(DB,{:age => 77})}.should_not raise_error
      #i.delete(DB)
      deleted = AnObject.find(DB,{:age => 77})
      deleted.should == []
    end
  end
  
  context "Using class to perform statements that changes multiple rows" do
    specify "should update multiple rows" do
      i1 = DBStruct_spec.create_test_object
      i1.insert(DB)
      i2 = DBStruct_spec.create_test_object
      i2.insert(DB)
      lambda {AnObject.update!(DB, {:name => 'Donald'}, :name => 'Dolly')}.should_not raise_error
   
      from_db = AnObject.find(DB,{:name => 'Dolly'}).first
      from_db.name.should == 'Dolly'      
    end
    
    specify "should delete multiple rows" do
      
    end
  end
  
  context "Use indirect approach to save and store objects" do
    setup do
    end
    
    specify "should be able to insert and read object indirectly" do
      r = DBStruct_spec.create_test_object
      r.age = 88
      DB[:person].insert(r.save)
      
      row = DB[:person].filter({:age => 88})
      from_db = AnObject.create(row).first
      from_db.name.should == r.name 
      from_db.age.should == r.age
      from_db.amount == r.amount
    end
  end 
end
