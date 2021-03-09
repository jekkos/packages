#!/bin/sh

INTERFACE=$1

INTERFACE=${INTERFACE:="br-lan"}
#default-value for INTERVAL
INTERVAL=${COLLECTD_INTERVAL:=30}
# COLLECTD_INTERVAL may have trailing decimal places, but sleep rejects floating point.
INTERVAL=$(printf %.0f $INTERVAL)
BASEDIR=$(dirname "$0")

LASTCHR=$((5+1))

while true; do

  #get data from amprate-tool. for each connection there are 2 lines (RX/TX)
  int6krate -i $INTERFACE all |
    
    while IFS= read -r line
    do
    EPOCH=$(date +%s)
    #for each line get parameter to variables
    echo "$line" | {
      IFS=' ' read -r iface src dst typ speed size primary 

      #convert string to number
      speed=${speed#0}

      #remove : from mac-addresses
      src=${src//[:]/}
      dst=${dst//[:]/}

      #filter connections
      #'amprate all' returns between 2 devices double results (src -> dst and dst->src)
      #we only take these connections where the src-mac is lesser than the dst-max
      if [[ "$(echo $src $dst| awk '{ print ($1 < $2) ? "true" : "false" }')" == "true" ]]
      then

        #shorten addresses
        src=$(echo $src|tail -c$LASTCHR)
        dst=$(echo $dst|tail -c$LASTCHR)

        if [ -s "$BASEDIR/plc-lookup.txt" ]
        then
          while read mac name; do
              if [[ $mac == $src ]]
              then
                  src=$name
              fi
          done <"$BASEDIR/plc-lookup.txt"

          while read mac name; do
              if [[ $mac == $dst ]]; then
                  dst=$name
              fi
          done <"$BASEDIR/plc-lookup.txt"

        fi
        #write data to collectd
        echo "PUTVAL \"$COLLECTD_HOSTNAME/exec-plc/plc_${typ}-${src}_${dst}\" interval=$INTERVAL $EPOCH:$speed"
      fi

  }


  done
  sleep $INTERVAL
done

