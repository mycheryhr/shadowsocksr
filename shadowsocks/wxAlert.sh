#!/bin/bash
## crontab 
## */1 * * * * /root/shadowsocksr/shadowsocks/wxAlert.sh > /dev/null 2>&1

HOUR=`date "+%H"`
MINUTE=`date "+%M"`
LOG="/tmp/conn_ssr.log"

number=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |awk -F "[:]" '/33520/{print $2}' |awk -F "    " '{print $2}' |sort -u`

#微信企业号的CropID
CropID='wx80179d3a3eb675c2'
#企业号中发送告警的应用
Secret='rf8zW7iF-VECQVwKGndrHzAkEqfcnmSXmhIGUHCKH24'
GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
Gtoken=$(/usr/bin/curl -s -G $GURL |  awk -F "[\":,]" '{print $15}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"

function body() {
    local int AppID=1
    #Appid 填写企业号中建立的报警APP的ID
    local UserID="@all"
    #此处填写报警接收用户，全部报警可留空
    local PartyID="@all"
    local TagID="@all"
    Ent=$'\n'
    Date=$(date '+%Y年%m月%d日 %H:%M:%S\n')
    Tit="服务器告警(V*P*N) IP:`cat $LOG | sort -u | grep -vE "^$|#|;" | tr ' ' '\n' |wc -l`"
    Content=`cat $TMP1`
    Msg=$Date$Ent$Content
    #Msg=$Date$Tit$Ent$(cat /tmp/message.txt|sed 's/%//g')
    #拼接msg主体文件,包含日期,主题,报警内容.并删除报警内容中的'%'号.
    #Url="http://www.zabbix.com"
    #Pic="http://cdn.aixifan.com/dotnet/20130418/umeditor/dialogs/emotion/images/ac/35.gif"
    #Pic="http://cdn.aixifan.com/dotnet/20130418/umeditor/dialogs/emotion/images/ac2/24.gif"
    printf '{\n'
    printf '\t"touser": "'"$UserID"\"",\n"
    printf '\t"toparty": "'"$PartyID"\"",\n"
    printf '\t"totag": "'"$TagID"\"",\n"
    printf '\t"msgtype": "news",\n'
    printf '\t"agentid": "'" $AppID "\"",\n"
    printf '\t"news": {\n'
    printf '\t"articles": [\n'
    printf '{\n'
    printf '\t\t"title": "'"$Tit"\","\n"
    printf '\t\t"description": "'"$Msg"\","\n"
    printf '\t\t"url": "'"$Url"\","\n"
    printf '\t\t"picurl": "'"$Pic"\","\n"
    printf '\t}\n'
    printf '\t]\n'
    printf '\t}\n'
    printf '}\n'
}

echo $number| tr ' ' '\n' >> $LOG

if [[ ${MINUTE} -eq 0 ]];then
    if [ ${HOUR} -eq 8 -o ${HOUR} -eq 22 ];then
        TMP1=`mktemp`
        cat $LOG | sort -r |uniq -c |sort -n -t ' ' -k 2 -r | grep -vE "^$|#|;" > /tmp/ip.txt
        for i in `cat $LOG | sort -r |uniq -c |sort -n -t ' ' -k 2 -r| awk -F " " '{print $2}' | grep -vE "^$|#|;" | tr ' ' '\n'`; do taobaoip $i;done > /tmp/ipinfo.txt
        paste /tmp/ip.txt /tmp/ipinfo.txt > $TMP1
        curl -l -H "Content-type: application/json" -X POST -d "$(body )" $PURL
        cat $LOG | sort -u | grep -vE "^$|#|;" | tr ' ' '\n' >> /tmp/ALLIP
        rm -f $TMP1 $LOG
    fi
fi
