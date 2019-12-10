#!/bin/bash

# install MP4Box: sudo apt install -y gpac
# install jq: sudo apt-get install jq
# install ruby: sudo apt install ruby-full
# install twurl: gem install twurl

tweetString="Frizo Cam"
workPath="/home/pi/tweetbot"
videoFilePath="$workPath/pivideo"
uploadResult="$workPath/result.json"

# record
rm -f "$videoFilePath.h264"
rm -f "$videoFilePath.mp4"
raspivid -t 7000 -w 720 -h 1280 -fps 25 -b 1024000 -p 0,0,720,1280 -o "$videoFilePath.h264"
MP4Box -add "$videoFilePath.h264" "$videoFilePath.mp4" || true
if [ ! -f "$videoFilePath.mp4" ]; then
    echo "mp4 file not found"
    exit 1
fi

# file size
fileSize=$(stat --printf="%s" "$videoFilePath.mp4")
echo "file size: $fileSize"
rm -f "$uploadResult"

# upload
echo "upload INIT"
twurl -H upload.twitter.com "/1.1/media/upload.json" -d "media_category=tweet_video&command=INIT&media_type=video/mp4&total_bytes=$fileSize" > "$uploadResult"
if [ ! -f "$uploadResult" ]; then
    echo "upload result file not found"
    exit 1
fi
media_id_string=$(cat "$uploadResult" | jq -r '.media_id_string')
echo "media id: $media_id_string"
echo "upload APPEND"
twurl -H upload.twitter.com "/1.1/media/upload.json" -d "command=APPEND&media_id=$media_id_string&segment_index=0" -f "$videoFilePath.mp4" -F "media"
echo "upload FINALIZE"
twurl -H upload.twitter.com "/1.1/media/upload.json" -d "command=FINALIZE&media_id=$media_id_string"

# tweet
#timestamp="$(date +"%s")"
#$timestamp"
#echo "$tweetString"
echo "tweet status update"
twurl -d "status=$tweetString&media_ids=$media_id_string" /1.1/statuses/update.json
echo "

done."
