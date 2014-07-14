## rake is a bridge between rails sinatra and webrick thin

{% highlight ruby %}
class MyApp
	def call(env)
    	#env is the request info hash
    	[
        	200, # http status code
            {'Content-Type' => 'text/plain'}, # http header
            ["you requested " + env['PATH_INFO]] # http body
        ]
    end
end
{% endhighlight %}

## code and protocal

#### from rake to thin or webrick

* response

ruby code

```ruby
[
	200,
    {
    	"Content-Length" => "34",
        "Content-Type" => "text/html"
    }
    [
    	"<html>",
        "	<h1>cleantha</h1>",
        "</html>"
    ]
]
```

* protocal

```
HTTP/1.1 200 OK
Content-Length: 34
Content-Type: text/html

<html>
	<h1>cleantha</h1>
</html>
```

#### from rake to rails and sinatra application

* ruby code

```ruby
env = {
	"REQUEST_METHOD" => "GET",
    "PATH_INFO" => "/users/,
    "HTTP_VERSION" => "1.1",
    "HTTP_HOST" => "localhost",
    "HTTP_CONNECTION" => "close",
}
```

* protocal

```
GET /users HTTP/1.1
Host: localhost
Connection: close
```

