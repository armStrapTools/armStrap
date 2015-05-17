from lib import ui as UI
from lib import utils as Utils

def installRootFS(url, config, boards, status):
  file = boards['Common']['CpuArch'] + boards['Common']['CpuFamily'] + "-" + config['Distribution']['Family'] + "-" + config['Distribution']['Version'] + ".txz"
  status.update_main(text="Downloading RootFS image " + file, percent = status.getPercent())  
  Utils.download(url + "/" + file)
  status.update_item(name = "Installing RootFS", value = "-5")
  status.update_main(text="Extracting RootFS image " + file, percent = status.getPercent())  
  Utils.extractTar(file, "mnt")
  Utils.unlinkFile(file)
  status.update_item(name = "Installing RootFS", value = "-10")
  