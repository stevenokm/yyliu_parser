#!/bin/bash -e
SCHEDULE_SOURCE="http://nthucad.cs.nthu.edu.tw/~yyliu/schedule.html"
SCHEDULE_LOCAL="./schedule.html"
SCHEDULE_LOCAL_UTF8="./schedule.utf8.html"
SCHEDULE_ICAL="./schedule.ical"

curl $SCHEDULE_SOURCE > $SCHEDULE_LOCAL
#wget -O $SCHEDULE_LOCAL $SCHEDULE_SOURCE
iconv -f big5 -t utf8 $SCHEDULE_LOCAL > $SCHEDULE_LOCAL_UTF8
perl ./yyliu_parser.pl $SCHEDULE_LOCAL_UTF8 > $SCHEDULE_ICAL
