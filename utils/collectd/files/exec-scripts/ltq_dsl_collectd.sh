#!/bin/sh

INTERVAL=$(printf %.0f $COLLECTD_INTERVAL)                                                                                                                                                                        
TIME=$(date +%s) 

parse_output()
{

  if [ $# -ne 3 ]; 
    then echo "illegal number of parameters"
  fi
  local output="$1"
  IFS=$'\n'
  for bucket in $output; do
     IFS=' '
     for tone in $bucket; do
       bin=${tone:1:4}
       value=${tone:6:2}
       value=$(printf "%d" 0x${value:-0})  > /dev/null 2>&1
       [ ! -z "$bin" -a $? -eq 0 ] && echo "PUTVAL \"$COLLECTD_HOSTNAME/exec_dsl/dsl_$2-$3/$2-$bin\" interval=$INTERVAL N:$value"
     done;
     IFS=$'\n'
  done;
}

while true; do
  stats=$(/etc/init.d/dsl_control lucistat | sed -e 's/dsl.//g' ) 
  bangdown=$(dsl_cpe_pipe.sh g997bang 0)
  bangup=$(dsl_cpe_pipe.sh g997bang 1)
  sangdown=$(dsl_cpe_pipe.sh g997sang 0)
  sangup=$(dsl_cpe_pipe.sh g997sang 1)
 
  parse_output "$bangdown" "bit_allocation" "down"
  parse_output "$bangup" "bit_allocation" "up"
  parse_output "$sangdown" "snr_allocation" "down"
  parse_output "$sangup" "snr_allocation" "up"

  for entry in $stats; do
      field=$(echo "$entry" | cut -d'=' -f1)
      value=$(echo "$entry" | cut -d'=' -f2 | tr -d '"')
      case "$field" in
          noise_margin_down|noise_margin_up)
              type="snr";;
          line_attenuation_down|line_attenuation_up|signal_attenuation_down|signal_attenuation_up)
              type="snr";;
          power_mode_num)
              type="gauge";;
          line_uptime)
              type="uptime";;
          latency_down|latency_up)
              type="latency";;
          ginp_down|ginp_up)
              type="ginp_enabled";;
          bitswap_down|bitswap_up)
              type="bitswap_enabled";;
          data_rate_down|data_rate_up|max_data_rate_up|max_data_rate_down)
              type="bitrate";;
          errors_uas_near|errors_uas_far|errors_fec_near|errors_fec_far|errors_ses_near|errors_ses_far|errors_loss_near|errors_loss_far)
              type="duration";;
          errors_txretr_near|errors_txretr_far|errors_rxretr_near|errors_rxretr_far|errors_rxcorr_near|errors_rxcorr_far)
              type="counter";;
          line_mode_s|line_state_detail|power_mode_s|latency_s_down|latency_s_up|profile_s|line_state) 
              continue
              ;;
	*)
	 continue
          ;;
    esac
    echo "PUTVAL \"$COLLECTD_HOSTNAME/exec_dsl/dsl_$field/$type\" interval=$INTERVAL N:${value}"
    done
  sleep $INTERVAL
done
