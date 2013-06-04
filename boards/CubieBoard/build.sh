
# installOS is called once everything is mounted and ready. 

function installOS {
  case ${ARMSTRAP_OS} in
    [dD]*)
      buildDebian
      ;;
    [uU]*)
      buildUbuntu
      ;;
    *)
      buildDebian
      ;;
  esac
  buildKernel
  buildBoot
}
