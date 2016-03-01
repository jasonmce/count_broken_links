# from https://www.digitalocean.com/community/tutorials/how-to-find-broken-links-on-your-website-using-wget-on-debian-7
#
# We output the results to count_broken_links-$HOSTNAME, then grep the
# results for our number of broken links.
#!/bin/bash

# @todo make sure wget 1.14+ is installed
# @todo Load these from an include file.
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# Set some defaults
WARNING=1
CRITICAL=2

# note: if this is set to > 0 the /etc/hosts part is not recognized (may be a bug)
while [[ $# > 1 ]]
do
key="$1"

case $key in
# Nagios arguments.
    -w|--warning)
    WARNING="$2"
    shift # past argument
    ;;
    -c|--critical)
    CRITICAL="$2"
    shift # past argument
    ;;
# wget arguments.
    -H|--hostname)
    HOSTNAME="$2"
    shift # past argument
    ;;
    -p|--wait)
    WAIT="--wait=$2"
    shift # past argument
    ;;
    -R|--reject)
    REJLIST="--reject $2"
    shift # past argument
    ;;
    -A|--acclist)
    ACCLIST="--accept $2"
    shift # past argument
    ;;
    -l|--level)
    LEVEL="-l $2"
    shift # past argument
    ;;
    --path)
    URLPATH="$2"
    shift # past argument
    ;;
    *)
    echo "I do not understand your $1 argument"
    ;;
esac
shift # past argument or value
done


filename="/tmp/count_broken_links-"$HOSTNAME

# Possibly do a less destructive cleanup later, but for now...
rm ${filename}
rm ${filename}.short

wget --spider --recursive --no-directories --no-verbose --debug --reject-regex "\?" $WAIT $REJLIST $ACCLIST $LEVEL $IMAGES -o ${filename} --header='User-Agent: Mozilla/5.0' http://$HOSTNAME/$URLPATH

grep "Found no broken links." $filename
if [[ $? -eq 0 ]] ; then
  echo "No broken links found"
  exit $STATE_OK
fi

# Save a short list of referrer -> broken link pairs.
cat $filename | sed -n "/Referer\|^http\|broken/p" | grep -B 2 "broken" > ${filename}.short

count=$(grep -P '\d+ (?=broken)' -o $filename)

if [[ $WARNING -gt $count ]] ; then
  echo "Only" $count "broken links, acceptable."
  exit $STATE_OK
fi
if [[ $CRITICAL -gt $count ]] ; then
  echo $count "broken links, exceeds warning threshold."
  exit $STATE_WARNING
fi
if [[ $CRITICAL -lt $count ]] ; then
  echo $count "broken links, exceeds Critical threshold."
  exit $STATE_CRITICAL
fi

echo "Something weird is afoot"
exit $STATE_UNKNOWN

