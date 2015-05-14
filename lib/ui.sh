#!/bin/bash

# Message format is TIMESTAMP:COMMAND@DATA#EXTRADATA
function guiDialog {

  local TMP_TBY=$((${ANC_LIN} - 11))
  local TMP_TBX=$((${ANC_COL} - 2))
  local TMP_PRY=$((${ANC_LIN} - 7))
  local TMP_BTL=""
  local TMP_TTL=""
  local TMP_PTL=""

  if [ -z "${2}" ]; then
    local TMP_BTL="armStrap"
  else
    local TMP_BTL="${2}"
  fi
  
  if [ -z "${3}" ]; then
    local TMP_TTL="Progress log"
  else
    local TMP_TTL="${3}"
  fi
  
  if [ -z "${4}" ]; then
    local TMP_PTL="Progress"
  else
    local TMP_PTL="${4}"
  fi
  
  exec 0<${1}
  /usr/bin/dialog --no-shadow --begin 3 1 --backtitle "${TMP_BTL}" --title "${TMP_TTL}" --tailboxbg "${ARMSTRAP_LOG_FILE}" ${TMP_TBY} ${TMP_TBX} --and-widget --begin ${TMP_PRY} 1 --title "${TMP_PTL}" --gauge "Progress" 6 ${TMP_TBX}
}

function guiWorker {
  local TMP_RAW
  local TMP_STP
  local TMP_CMD
  local TMP_DTA
  local TMP_EXT
  local TMP_GUI=$(mktemp --tmpdir armStrap_UI.XXXXXXXX)
  local TMP_PID
  local TMP_VAL="${2}"
  local TMP_NAM="${1}"
  local TMP_TMP=""

  rm -f ${ARMSTRAP_GUI_FF1}
  rm -f ${ARMSTRAP_GUI_FF2}
  rm -f ${TMP_GUI}
  
  mkfifo -m 644 ${ARMSTRAP_GUI_FF1}
  mkfifo -m 644 ${ARMSTRAP_GUI_FF2}
  mkfifo -m 644 ${TMP_GUI}
    
  while [ "${TMP_CMD}" != "stop" ]; do
    read -r TMP_RAW <${ARMSTRAP_GUI_FF1}
    IFS="#"
    TMP_RAW=(${TMP_RAW})
    if [ ! -z "${TMP_RAW[1]}" ]; then
      TMP_EXT="${TMP_RAW[1]}"
    fi
    TMP_RAW=${TMP_RAW[0]}
    IFS="@"
    TMP_RAW=(${TMP_RAW})
    TMP_DTA=${TMP_RAW[1]}
    IFS=":"
    TMP_CMD=(${TMP_RAW[0]})
    TMP_STP=${TMP_CMD[0]}
    TMP_CMD=${TMP_CMD[1]}
    case ${TMP_CMD} in
       name) TMP_NAM="${TMP_DTA}"
             printf "%d:@" "${TMP_STP}" >${ARMSTRAP_GUI_FF2}
             ;;
      start) guiDialog "${TMP_GUI}" "${TMP_NAM}" "${TMP_DTA}" "${TMP_EXT}" &
             exec 3>${TMP_GUI}
             TMP_PID=""
             while [ -z "${TMP_PID}" ]; do
               TMP_PID=$(/usr/bin/pgrep -n dialog)
             done
             printf "%d:%s@%d" "${TMP_STP}" "${TMP_CMD}" ${TMP_PID} >${ARMSTRAP_GUI_FF2}
             ;;
      stop)  exec 3<&-
             /bin/kill ${TMP_PID}
             wait > /dev/null 2>&1
             /usr/bin/tset
             printf "%d:@" "${TMP_STP}" >${ARMSTRAP_GUI_FF2}
             ;;
       add)  TMP_VAL=$(expr ${TMP_VAL} + ${TMP_DTA})
             printf "XXX\n%d\n%s\nXXX\n" ${TMP_VAL} "${TMP_EXT}" >> ${TMP_GUI}
             printf "%d:%s@%d" "${TMP_STP}" "${TMP_CMD}" ${TMP_VAL} >${ARMSTRAP_GUI_FF2}
             ;;
       sub)  TMP_VAL=$(expr ${TMP_VAL} - ${TMP_DTA})
             printf "XXX\n%d\n%s\nXXX\n" ${TMP_VAL} "${TMP_EXT}" >> ${TMP_GUI}
             printf "%d:%s@%d" "${TMP_STP}" "${TMP_CMD}" ${TMP_VAL} >${ARMSTRAP_GUI_FF2}
             ;;
       set)  TMP_VAL=${TMP_DTA}
             printf "XXX\n%d\n%s\nXXX\n" ${TMP_VAL} "${TMP_EXT}" >> ${TMP_GUI}
             printf "%d:%s@%d" "${TMP_STP}" "${TMP_CMD}" ${TMP_VAL} >${ARMSTRAP_GUI_FF2}
             ;;
       get)  printf "%d:%s@%d" "${TMP_STP}" "${TMP_CMD}" ${TMP_VAL} >${ARMSTRAP_GUI_FF2}
             ;;
    esac
  done
  IFS="${ARMSTRAP_IFS}"
  
  rm -f ${ARMSTRAP_GUI_FF1}
  rm -f ${ARMSTRAP_GUI_FF2}
  rm -f ${TMP_GUI}
}

function guiWriter {
  if [ -z "${ARMSTRAP_GUI_DISABLE}" ]; then
    local TMP_RAW
    local TMP_CMD="${1}"  
    local TMP_DTA="${2}"
    shift
    shift
    local TMP_STP=$(date +%s)
    IFS="@"

    if [ -z "${@}" ]; then  
      printf "%d:%s@%s\n" ${TMP_STP} "${TMP_CMD}" "${TMP_DTA}" >${ARMSTRAP_GUI_FF1}
    else
      printf "%d:%s@%s#%s\n" ${TMP_STP} "${TMP_CMD}" "${TMP_DTA}" "${@}" >${ARMSTRAP_GUI_FF1}
    fi
    while  [ "${TMP_RAW}" != "${TMP_STP}" ]; do
      if [ -p "${ARMSTRAP_GUI_FF2}" ]; then
        read -r TMP_RAW <${ARMSTRAP_GUI_FF2}
        TMP_RAW=(${TMP_RAW})
        TMP_DTA=${TMP_RAW[1]}
        IFS=":"
        TMP_CMD=(${TMP_RAW[0]})
        TMP_STP=${TMP_CMD[0]}
        TMP_CMD=${TMP_CMD[1]}
        TMP_RAW=${TMP_STP}
      else
        TMP_RAW=${TMP_STP}
        TMP_DTA=""
      fi
    done

    if [ ! -z ${TMP_DTA} ]; then
      printf "%s\n" "${TMP_DTA}"
    fi
  
    IFS="${ARMSTRAP_IFS}"
  fi
}

function guiStart {
  if [ -z "${ARMSTRAP_GUI_DISABLE}" ]; then
    ARMSTRAP_LOG_SILENT="Yes"
    guiWorker "${1}" "${ARMSTRAP_GUI_PCT}" &
  
    while [ ! -p "${ARMSTRAP_GUI_FF1}" ]; do
      sleep 0.1
    done
  
    while [ ! -p "${ARMSTRAP_GUI_FF2}" ]; do
      sleep 0.1
    done
  fi
  
}

function guiStop {
  if [ -z "${ARMSTRAP_GUI_DISABLE}" ]; then
    ARMSTRAP_LOG_SILENT="No"
    ARMSTRAP_GUI_PCT=$(guiWriter "get")  
    sleep 1

    local TMP=$(guiWriter "stop")
  
    while [ -p "${ARMSTRAP_GUI_FF1}" ]; do
      sleep 0.1
    done
  
    while [ -p "${ARMSTRAP_GUI_FF2}" ]; do
      sleep 0.1
    done
  fi
}
