ANS_BLD=""
ANS_DIM=""
ANS_REV=""
ANS_RST=""
ANS_SUL=""
ANS_RUL=""
ANS_SSO=""
ANS_RSO=""
	
ANF_BLK=""
ANF_RED=""
ANF_GRN=""
ANF_YEL=""
ANF_BLU=""
ANF_MAG=""
ANF_CYN=""
ANF_GRA=""
ANF_DEF=""
	
ANB_BLK=""
ANB_RED=""
ANB_GRN=""
ANB_YEL=""
ANB_BLU=""
ANB_MAG=""
ANB_CYN=""
ANB_GRA=""
ANB_DEF=""

function detectAnsi {
  local TMP_TPUT="`/bin/which tput`"

  if [ ! -z "${TMP_TPUT}" ]; then
    if [ `${TMP_TPUT} colors` -ge 8 ]; then
        ANS_BLD="`${TMP_TPUT} bold`"
        ANS_DIM="`${TMP_TPUT} dim`"
        ANS_REV="`${TMP_TPUT} rev`"
        ANS_RST="`${TMP_TPUT} sgr0`"
        ANS_SUL="`${TMP_TPUT} smul`"
	ANS_RUL="`${TMP_TPUT} rmul`"

	ANS_SSO="`${TMP_TPUT} smso`"
	ANS_RSO="`${TMP_TPUT} rmso`"
	
	ANF_BLK="`${TMP_TPUT} setaf 0`"
	ANF_RED="`${TMP_TPUT} setaf 1`"
	ANF_GRN="`${TMP_TPUT} setaf 2`"
	ANF_YEL="`${TMP_TPUT} setaf 3`"
	ANF_BLU="`${TMP_TPUT} setaf 4`"
	ANF_MAG="`${TMP_TPUT} setaf 5`"
	ANF_CYN="`${TMP_TPUT} setaf 6`"
	ANF_GRA="`${TMP_TPUT} setaf 7`"
	ANF_DEF="`${TMP_TPUT} setaf 9`"
	
	ANB_BLK="`${TMP_TPUT} setab 0`"
	ANB_RED="`${TMP_TPUT} setab 1`"
	ANB_GRN="`${TMP_TPUT} setab 2`"
	ANB_YEL="`${TMP_TPUT} setab 3`"
	ANB_BLU="`${TMP_TPUT} setab 4`"
	ANB_MAG="`${TMP_TPUT} setab 5`"
	ANB_CYN="`${TMP_TPUT} setab 6`"
	ANB_GRA="`${TMP_TPUT} setab 7`"
	ANB_DEF="`${TMP_TPUT} setab 9`"
    fi
  fi
}

detectAnsi

