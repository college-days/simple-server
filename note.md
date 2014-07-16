## rake

rake + config.ru

## concurrent

543142d这一次提交，提交信息为```now use builder and config.ru```

这一次的提交的代码中server已经初步成型，嵌入了rake，但是还有一个问题就
是这个server面对请求并不是并发的

比如启动一个server

```shell
ruby tube.rb
```

然后开启两个客户端连接

```shell
curl localhost:3000/sleep
curl localhost:3000
```

可以看到两个连接都是过了5秒之后才返回结果，这就是因为第一个连接访问了
sleep路径，导致server沉睡5s，而由于当前server并不是并发的，导致后面访
问的连接都被阻塞住了，只有等server醒过来才能继续响应，下一步就是要搞并
发

## fork wait

fork是用来创建一个和父进程完全相同上下文的子进程
wait是用来销毁子进程，等待子进程结束，防止出现僵尸进程

详情参考csapp一书

## concurrent

b415552这一次提交，提交信息是```finish concurruent use multi-threads
and multi-processes```，使用了fork来创建多进程并发

开启一个server

```shell
ruby tube.rb
```

```shell
ps => 查看当前进程可以看到有四个ruby tube.rb创建处理的进程，因为fork了
三次，创建了三个子进程
```

```shell
curl localhost:3000
```

每次都可以看到是不同的进程在处理请求，打印出来的pid每一次都不会一样，
是由cpu来调度的

## eventmachine

和nodejs的eventloop一样，都是单进程的，如果服务器内部有大计算量阻塞，
那么所有的访问都会被block住，然后等计算完之后才会继续响应请求，所以依
然像上面那样用curl localhost:3000/sleep请求的话，再开其他窗口正常请求
也是会被阻塞住的，所以eventloop只适合I/O密集型的，不适合CPU密集型的。写了一
个测试并发的脚本，concurrent_test.sh，可以把服务器跑起来

```shell
ruby tube.rb
```

然后再开两个命令行分别执行测试脚本

```shell
./concurrent_test.sh
```

可以看到每次返回的pid都是一样的

关于reactor模式，或者说是事件循环，是一种非阻塞的IO机制，也就是说对付
耗时的IO操作不必等到数据返回再进行后面的操作，而刚才用的请求sleep，然
后其他的requests操作也阻塞住了，是因为本身EM就是单进程单线程的，sleep
之后相当于这个进程啥都不干了，纯睡眠了，所以必然会把其他的所有的请求操
作都挂起了，这也是模拟了一个耗时的cpu计算过程，因为cpu密集型的操作就是
进行大量的运算，最终还是消耗单个进程的资源的，所以cpu密集型对于EM来说
必须妥妥的阻塞了，但是对于IO密集型，是不需要消耗cpu资源去计算，只是读
取其他地方传过来的数据或者发送数据到其他地方，所以只要注册了事件读写事
件，读完或者写完以后再通知就行了，然后就
可以去做其他的读写IO操作了

所以在Reactor中reactor本身是同步的，也就是说它在循环中触发每一个
handler都需要等到handler有东西返回他才会走，所以只能是说每一个handler
都要用异步的写法协程回调函数，要把handler写成一个callback，这样就不会
阻塞住reactor主线程了，比如做一个循环，如果协程同步的写法，就必须等到
这个大循环执行完之后reactor才会去处理其他的事情，所以必须把这个大循环
写成回调的形式协程异步的，这样就不会阻塞reactor了，详细写法见rubyconf
的视频

reactor是同步非阻塞的，在此种方式下，用户进程发起一个IO操作以后边可返
回做其它事情，但是用户进程需要时不时的询问IO操作是否就绪，这就要求用户
进程不停的去询问，从而引入不必要的CPU资源浪费。其中目前JAVA的NIO就属于
同步非阻塞IO，每一次事件循环都去问你做了没有，没做的话就做，并且是同步
的要得到返回值才会进行下一步

select/poll,epoll I/O多路复用
kqueue epoll
看看csapp

* [异步式 I/O 与事件驱动](http://www.ituring.com.cn/article/5779) 
* [web优化必须了解的原理之I/o的五种模型和web的三种工作模式](http://litaotao.blog.51cto.com/6224470/1289790)
* [怎样理解阻塞非阻塞与同步异步的区别？](http://www.zhihu.com/question/19732473)
* [epoll 或者 kqueue 的原理是什么？](http://www.zhihu.com/question/20122137)
* [Linux 开发，使用多线程还是用 IO 复用 select/epoll？](http://www.zhihu.com/question/20114168)
* [Reactor和Proactor模式比较, 也讲到了阻塞非阻塞，同步非同步](http://liuxun.org/blog/reactor-he-proactor-mo-shi-bi-jiao/)
* [Research on EventMachine](http://blog.csdn.net/resouer/article/details/7975550)
* [多线程编程与事件驱动编程对比](http://www.xiaoyaochong.net/wordpress/index.php/2013/03/24/%E5%A4%9A%E7%BA%BF%E7%A8%8B%E7%BC%96%E7%A8%8B%E4%B8%8E%E4%BA%8B%E4%BB%B6%E9%A9%B1%E5%8A%A8%E7%BC%96%E7%A8%8B%E5%AF%B9%E6%AF%94/)
* [Netty源码解读（四）Netty与Reactor模式](http://ifeve.com/netty-reactor-4/)
* [网络编程之Reactor 模式](http://www.cnblogs.com/eally-sun/p/3463280.html)

>reactor只适合IO密级的任务,因为IO密集的情况下CPU大部分时间在等待IO,所
>以可以充分利用,在等IO的时候去执行其他任务这就可以达到高并发,尤其是基
>于web的，很多时候都是在等待IO,反观,如果是计算密集型的,就没用了,还是要
>靠多线程，当然最后注意一点reactor自身是同步的，但是挂载在reactor上注
>册执行的handler必须是异步的，不然就会block住reactor，反而降低了效率

因为用线程啥的是同步的，如果是一个数据库查询，必然是要等到查询结果返回
那么才会去做其他事情，也就是同步阻塞式的，而使用非阻塞的方式可以将这些
白白等待的时间去用来处理其他的I/O业务

#### never block the reactor

reactor is simply a single threaded while loop called the "reactor
loop"

your code "reacts" to incoming events

if your event handler takes too long, other events cannot fire

* no sleep(1)
* no long loops (100_000.times)
* no blocking I/O (mysql queries)
* no polling(_轮询操作_) (while !condition)

关于第一条第二条和第三条已经很清楚了，对已第三条，可能会有点疑惑，
reactor不是本身就是一种高并发的IO模型嘛，难道还不支持数据库查询了，
其实这里说的mysql query指的使用mysql这个gem包，mysql这个驱动只支持同步，
而[mysql2](https://github.com/brianmario/mysql2)支持异步模式，以为如果
是同步模式查询的话，势必会耗cpu的资源来进行查询计算，从而阻塞住reactor
进程，相当于是1，2，4这三种情况了，如果使用异步模式的话不管数据有没有
查询到那都先返回，不会阻塞住reactor的轮询进程，因为reactor本身是一个循
环，这个循环中检测到各种事件，然后调用对应的回调函数去处理，所以注册上
去的回调函数必须也是异步的，不能阻塞住这个reactor的轮询进程，reactor本
身是同步的，注册上去的事件必须是异步的，不知道这样的理解对不对

[通过fiber把异步变成同步](https://github.com/igrigorik/em-synchrony)
[异步的activerecord](https://github.com/brianmario/mysql2#asynchronous-active-record)

## 关于回调

实际上之前笔记里也记过了，回调的实现机制就是根据的continuation的概念，
保存上下文然后切换回去，回调基于的时cps也就是continuation passing
style，传递的是一个continuation，也就是传递的是一个保存好的上下文并且
下一次要执行的起点

像nodejs那样回调套回调的去实现业务逻辑肯定是一件很痛苦的事情，ruby的EM
其实提供的是一种用同步方式去写异步回调的体验，EM是同步非阻塞的，因为是
基于reactor实现的，reactor是同步非阻塞的

## coroutine(fiber)协程或者纤程

多个continuation之间来回的切换，使用call/cc切换，就可以实现一个
coroutine，有一个概念务必搞清楚，并发并不是并行，你执行一伙我执行一伙
才是并发，csapp和之前的笔记中也有记录

## 关于非阻塞，阻塞 与 同步，异步两组概念
