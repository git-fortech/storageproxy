#!/bin/bash

dir=`dirname $0`
. $dir/s3cfg


#aw2 args 
exp=$(date +%s)
exp=`expr $exp + 86400`
exp=$(date -d @$exp)
param="AWSAccessKeyId=${accessid}&Signature=${signature}&Expires=$exp"

curl -v "http://$host:$port/test_aws2_args?$param"


#aw2 headers 
curl -v                                                                        \
 -H "Host: ${host}"                                                            \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X PUT "http://$host:$port/test_aws2_headers"



#aw4 args 
date=$(date --utc +%Y%m%d)
dtime=$(date --utc +%Y%m%dT%H%M%SZ)
param="X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=${accessid}/${date}/cn/s3/aws4_request&X-Amz-Date=${dtime}&X-Amz-Expires=86400&X-Amz-Signature=${signatureV4}&X-Amz-SignedHeaders=host,x-amz-content-sha256"

curl -v                                                           \
 -H "Host: ${host}"                                               \
 -H "x-amz-content-sha256: STREAMING-AWS4-HMAC-SHA256-PAYLOAD"    \
    "http://$host:$port/test?$param"


#aw4 header
date=$(date --utc +%Y%m%d)
dtime=$(date --utc +%Y%m%dT%H%M%SZ)
curl -v                                                      \
 -H "Host: ${host}"                                          \
 -H "X-Amz-Date: ${dtime}"                                   \
 -H "x-amz-content-sha256: UNSIGNED-PAYLOAD"                 \
 -H "Authorization: AWS4-HMAC-SHA256 Credential=${accessid}/${date}/cn/s3/aws4_request,SignedHeaders=host;xmz-date;x-amz-content-sha256,Signature=${signatureV4}"     \
 -L -X PUT "http://$host:$port/test"




#aw2 virtual hosted-style 
virtual_host=s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/testbuck/dirA/dirB/file3"

#aw2 virtual hosted-style 
virtual_host=s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/testbuck/"

#aw2 virtual hosted-style 
virtual_host=s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/testbuck"


#aw2 virtual hosted-style 
virtual_host=s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/"



#aw2 virtual hosted-style 
virtual_host=s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port"



#aw2 virtual hosted-style 
virtual_host=johnsmith.s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/dir1/dir2/file?acl&policy=&versionId=30&response-content-encoding=gzip"


#aw2 virtual hosted-style 
virtual_host=johnsmith.s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X DELETE "http://$host:$port/?delete=obj1,obj2"



#aw2 virtual hosted-style 
virtual_host=johnsmith.s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port/"


#aw2 virtual hosted-style 
virtual_host=johnsmith.s3.amazonaws.com
curl -v                                                                        \
 -H "Host: ${virtual_host}"                                                    \
 -H "Authorization: AWS ${accessid}:${signature}"                              \
 -L -X GET "http://$host:$port"
