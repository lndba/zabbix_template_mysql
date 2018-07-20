# Zabbix之MySQL监控模板详解
## zabbix agent配置
1. 上传监控MySQL脚本和更改check_list.txt

```
[root@linux-node1 ~]# ll /server/scripts/zabbix_monitor/monitor_mysql.sh
-rwxr-xr-x 1 root root 4020 Aug 16 10:49 /server/scripts/zabbix_monitor/monitor_mysql.sh
[root@linux-node1 ~]# chmod +x /server/scripts/zabbix_monitor/monitor_mysql.sh
[root@linux-node1 ~]# chown zabbix.zabbix /server/scripts/zabbix_monitor/check_list.txt
[root@linux-node1 ~]# chmod 600 /server/scripts/zabbix_monitor/check_list.txt
```

2. 将自定义监控文件monitor.conf文件上传到/etc/zabbix/zabbix_agentd.d下

```
[root@linux-node1]# cat /etc/zabbix/zabbix_agentd.d/monitor.conf
# MySQL Status
UserParameter=mysql.discovery,/server/scripts/zabbix_monitor/monitor_mysql.sh discovery
UserParameter=mysql.slave.discovery,sh /server/scripts/zabbix_monitor/monitor_mysql.sh slave_discovery
UserParameter=mysql.ping[*],sh /server/scripts/zabbix_monitor/monitor_mysql.sh ping $1
UserParameter=mysql.slave_status[*],sh /server/scripts/zabbix_monitor/monitor_mysql.sh slave_status $1
UserParameter=mysql.tmpfile.md5[*],sh /server/scripts/zabbix_monitor/monitor_mysql.sh tmpfile_md5 $1
UserParameter=mysql.perf[*],sh /server/scripts/zabbix_monitor/monitor_mysql.sh perf $2 $1
```

3. zabbix agent配置文件开启agent主动模式

```
[root@linux-node1 ~]# vim /etc/zabbix/zabbix_agentd.conf
ServerActive=192.168.56.11
```

4. 配置MySQL信息

```
[root@linux-node1 ~]# cat /server/scripts/zabbix_monitor/check_list.txt
mysql:  3306    slave  zabbix zabbix123.Com
proc:   mysqld
```

5. check_list.txt文件配置MySQL信息详解

第一行：服务名，端口号，主从，MySQL用户名，MySQL密码
第二行：进程，进程名
温馨提示：数据库账号授权方法：
GRANT USAGE,PROCESS,REPLICATION CLIENT,REPLICATION SLAVE ON *.* TO 'zabbix'@'localhost' IDENTIFIED BY 'zabbix123.Com';
flush privileges;

##Zabbix界面配置
1. 导入模版
![](media/15320914268637/15320923293018.jpg)

2. 选择导入摸板
![](media/15320914268637/15320924407503.jpg)

3. 添加自动发现所需的正则表达式
![](media/15320914268637/15320925021953.jpg)

4. 新建表达式
![](media/15320914268637/15320925701131.jpg)

5. 添加正则表达式完成
![](media/15320914268637/15320926427916.jpg)

6. 到此为止，MySQL监控模板就可以正常使用了

