#!/bin/bash
#===================Script Description===================
#Scripts_name     : monitor_mysql.sh
#Version          : V1.0.1
#Scripts_function : This script applies to MySQL monitoring based on the ZABBIX template.
#Author           : 行思(Lionel Wang)
#E_mail           : zhiwei_wang@163.com
#QQ               : 805022948
#Blog             : www.lndba.com
#Create date      : 2016-08-15
#========================================================
. /etc/profile
. /etc/bashrc

mysql_cli=$(which mysql 2> /dev/null)
mysql_cli=${mysql_cli:=/application/mysql/bin/mysql}
mysql_cli=${mysql_cli:=/usrl/local/mysql/bin/mysql}
cwdir=`dirname $0`
check_list=${cwdir}/check_list.txt

if [ ! -z "$2" ];then
    port=$2
else
    port=3306
fi


str_md5() {
    echo $1 | md5sum | awk '{ print $1 }'
}


json_null() {
    printf '{\n'
    printf '\t"data":[\n'
    printf  "\t\t{ \n"
    printf  "\t\t\t\"{#PORT}\":\"NULL\"}]}\n"
}

tmpfile=/tmp/.$(str_md5 ${port}.mysql).zbx

if [ -f $check_list ];then
    user=$(grep $port $check_list | awk '{ print $4 }')
    password=$(grep $port $check_list | awk '{ print $5 }')
fi

user=${user:=lionel}
password=${password:=123456}
host=${host:=localhost}
mysql_connect="${mysql_cli} -u$user -p$password -h$host -P$port"

mysql_discovery() {
    if [ ! -f "$check_list" ];then
        json_null
        exit 2
    fi
    ports=($(grep -v '^#' $check_list | grep '^mysql:' | awk '{ print $2 }'))
    if [ ${#ports[@]} -eq 0 ];then
        json_null
        exit 1
    fi
    printf '{\n'
    printf '\t"data":[\n'
    for((i=0;i<${#ports[@]};++i)) {
        num=$(echo $((${#ports[@]}-1)))
        if [ "$i" != "${num}" ]; then
            printf "\t\t{ \n"
            printf "\t\t\t\"{#PORT}\":\"${ports[$i]}\"},\n"
        else
            printf  "\t\t{ \n"
            printf  "\t\t\t\"{#PORT}\":\"${ports[$num]}\"}]}\n"
        fi
    }
}

slave_discovery() {
    if [ ! -f "$check_list" ];then
        json_null
        exit 2
    fi
    ports=($(grep -v '^#' $check_list| grep "^mysql:" | grep 'slave' | awk '{ print $2 }'))
    if [ ${#ports[@]} -eq 0 ];then
        json_null
        exit 1
    fi
    printf '{\n'
    printf '\t"data":[\n'
    for((i=0;i<${#ports[@]};++i)) {
        num=$(echo $((${#ports[@]}-1)))
        if [ "$i" != "${num}" ]; then
            printf "\t\t{ \n"
            printf "\t\t\t\"{#PORT}\":\"${ports[$i]}\"},\n"
        else
            printf  "\t\t{ \n"
            printf  "\t\t\t\"{#PORT}\":\"${ports[$num]}\"}]}\n"
        fi
    }
}

mysql_ping() {
        $mysql_connect -e 'show global status' 2> /dev/null > $tmpfile && $mysql_connect -e 'show global variables' 2> /dev/null >> $tmpfile && $mysql_connect -e 'show slave status\G' 2> /dev/null  >> $tmpfile && echo 1 || echo 0
}

mysql_perf() {
    data=$(grep "\<$1\>" $tmpfile | awk '{ print $2 }')
    if [ -n "$data" ];then
        echo $data
    fi
}

slave_status() {
        slave_running=`mysql_perf 'Slave_IO_State'`
        io_running=`mysql_perf 'Slave_IO_Running'` 
        sql_running=`mysql_perf 'Slave_SQL_Running'`
        if [ "$slave_running" != '' ];then
            if [ "$io_running" == 'No' -o "$sql_running" == 'No' ];then
                echo 0
            else
                echo 1
            fi
        else
            if [ "$io_running" == 'Yes' -a "$sql_running" == 'Yes' ];then
               echo 1
            else
               echo 3
            fi
        fi
        
}


tmpfile_md5() {
    /usr/bin/md5sum $tmpfile 2> /dev/null | awk '{ print $1 }' || echo "7410"
}

case $1 in
    discovery)
        mysql_discovery
        ;;
    slave_discovery)
        slave_discovery
        ;;
    ping)
        mysql_ping
        ;;
    slave_status)
        slave_status
        ;;
    tmpfile_md5)
        tmpfile_md5
        ;;
    perf)
        if [ -z "$3" ];then
            echo 7410
        else
            mysql_perf $3
        fi
        ;;
    *)
        usage="Usage: $0 discovery | slave_discovery | ping | slave_status | tmpfile_md5 | perf  port [options]"
        echo $usage
        ;;
esac
