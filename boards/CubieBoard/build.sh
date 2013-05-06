
# installOS is called once everything is mounted and ready. 

function installOS {
  buildRoot
  buildKernel
  buildBoot
}
