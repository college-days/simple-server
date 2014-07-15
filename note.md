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
