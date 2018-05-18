require "spec_helper"

describe Hedgerow do

  before do
    @client1 = Mysql2::Client.new(host: "localhost", username: "hedgerow", password: "hedge_a_row")
    @client2 = Mysql2::Client.new(host: "localhost", username: "hedgerow", password: "hedge_a_row")
    Hedgerow.connection = @client1
  end

  it "executes code inside the block" do
    value = 0
    Hedgerow.with("test_name") do
      value = 20
    end
    expect(value).to eql(20)
  end

  it "releases a lock when a block finishes" do
    value = nil

    Hedgerow.with("test_name") do
      value = 20
    end

    Hedgerow.connection = @client2

    Hedgerow.with("test_name") do
      value = 90
    end

    expect(value).to eql(90)
  end

  it "raises an error when it cannot get a lock" do
    expect do
      Hedgerow.with("test_name") do
        Hedgerow.connection = @client2
        Hedgerow.with("test_name", timeout: 1) do
        end
      end
    end.to raise_exception(Hedgerow::LockFailure)
  end
end
