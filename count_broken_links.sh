# from https://www.digitalocean.com/community/tutorials/how-to-find-broken-links-on-your-website-using-wget-on-debian-7
#
# We output the results to /tmp/count_links, then grep the
# results to see if we passed or failed.
#!/bin/bash

# @todo Load these from an include file.
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4


# Some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to > 0 the /etc/hosts part is not recognized (may be a bug)

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -h|--hostname)
    HOSTNAME="$2"
    shift # past argument
    ;;
    -p|--pause)
    PAUSE="$2"
    shift # past argument
    ;;
    -w|--warning)
    WARNING="$2"
    shift # past argument
    ;;
    -c|--critical)
    CRITICAL="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done

filename="/tmp/count_broken_links-"$HOSTNAME

wget --spider -r -nd -nv --reject-regex "\?" --header='User-Agent: Mozilla/5.0' -o $filename http://$HOSTNAME/

grep "Found no broken links." $filename
if [ $? -eq 0 ] ; then
  echo "No broken links found"
  exit $STATE_OK
fi

count=$(grep -P '\d+ (?=broken)' -o $filename)

if [ $WARNING -gt $count ] ; then
  echo "Only" $count "broken links, acceptable."
  exit $STATE_OK
fi
if [ $CRITICAL -gt $count ] ; then
  echo $count "broken links, exceeds warning threshold."
  exit $STATE_WARNING 
fi
if [ $CRITICAL -lt $count ] ; then
  echo $count "broken links, exceeds Critical threshold."
  exit $STATE_CRITICAL
fi

echo "Something weird is afoot"
exit $STATE_UNKNOWN

