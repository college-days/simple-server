for((i=1;i<=10;i++));
    #do echo $(expr $i \* 4);
    do curl localhost:3000;sleep 1;
done
