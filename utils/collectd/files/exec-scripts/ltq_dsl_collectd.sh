#!/bin/sh

# COLLECTD_INTERVAL may have trailing decimal places, but sleep rejects floating point.
INTERVAL="${COLLECTD_INTERVAL:-60.000}"
HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"

while true; do
  stats=$(/etc/init.d/dsl_control lucistat | sed -e 's/dsl.//g' ) 
  IFS=$'\n'
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
    echo "PUTVAL \"$COLLECTD_HOSTNAME/dsl_$field/$type\" interval=$INTERVAL N:${value}"
    done
  sleep $INTERVAL
done
