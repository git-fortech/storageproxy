#!/bin/bash

dir=`dirname $0`
. $dir/s3cfg

bucket=
objname=
file=
agent=

function usage()
{
    echo "Usage: putobj.sh -b {bucket} -o {object} [-f {local-file}] [-a {user-agent}] -h"
}

while getopts "b:o:f:a:h" opt ; do
    case $opt in
        b)
            bucket=$OPTARG
            ;;
        o)
            objname=$OPTARG
            ;;
        f)
            file=$OPTARG
            ;;
        a)
            agent=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            echo "Error: unrecognized option $opt"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$bucket" ]] || [[ -z "$objname" ]] ; then
    echo "Error: argument bucket or object is missing"
    usage
    exit 1
fi

date=$(date --utc -R)

opt_T=
length=0
if [ -n "$file" ] ; then
    length=`ls -l $file | tr -s ' ' | cut -d ' ' -f 5`
    opt_T="-T $file"
fi

header="PUT\n\ntext/plain\n${date}\n/$bucket/$objname"
#StringToSign = HTTP-Verb + "\n" +   --> PUT \n
#    Content-MD5 + "\n" +            --> "" \n
#    Content-Type + "\n" +           --> "text/plain" \n
#    Date + "\n" +                   --> ${date} \n
#    CanonicalizedAmzHeaders +       --> "" 
#    CanonicalizedResource;          --> /$bucket/$objname

sig=$(echo -en ${header} | openssl sha1 -hmac ${secret} -binary | base64)

if [ -z "$agent" ] ; then
  curl -v                \
      -H "Date: ${date}" \
      -H "Host: $host"   \
      -H "Expect:"       \
      -H "Content-Length: ${length}"          \
      -H "Content-Type: text/plain"           \
      -H "Authorization: AWS ${token}:${sig}" \
      -L -X PUT "http://$host/$bucket/$objname" $opt_T 
else
  curl -v                \
      -H "Date: ${date}" \
      -H "Host: $host"   \
      -H "Expect:"       \
      -H "Content-Length: ${length}"          \
      -H "Content-Type: text/plain"           \
      -H "Authorization: AWS ${token}:${sig}" \
      -H "User-Agent: $agent"                 \
      -L -X PUT "http://$host/$bucket/$objname" $opt_T
fi
