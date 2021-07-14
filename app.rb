class MyApp
  def self.call(env)
    [200, { 'Content-Type' => 'text/plain' }, 'hello']
  end
end
