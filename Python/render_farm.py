import os, sys
import subprocess
from subprocess import Popen
import threading
import time
#import blend_render_info

class Main:
  def __init__(self):
      self.null_file_handle = open(os.devnull, "w")
      self.start_time = {}
      self.duration_time = {}
      
      self.ssh_ok = []
      # seconds between console updates during render
      self.time_delay = 1
      self.num_strips = 20
      
      
  @staticmethod
  def sec_to_hms(t):
    """
    convert floating-point seconds
    into d hh:mm:ss.ss string
    """
    sign = (' ', '-')[t < 0]
    t = abs(t)
    sec = t % 60
    t //= 60
    minute = t % 60
    t //= 60
    hour = t % 24
    day = t // 24
    return '%s%dd %02d:%02d:%05.2f' % (sign, day, hour, minute, sec)
  
  def monitor_renders(self, process_start, blender_string):
      busy = True
      #count = 0
      while busy:
        busy = False
        active = []
        for machine in range(self.num_strips):
          # an entry in "duration_time" signals completion
          if machine+1 not in self.duration_time:
            busy = True
            active.append(machine+1)
        # if some mechines are still rendering
        time.sleep(1)
  
  def threaded_call(self, machine, blender_script_path, apos, bpos, strip_number):
      #this is where I actually launch the thread for each machine
      com = ["ssh", "username@ip_address{:02d}".format(machine), "blender", "-b", blender_script_path, "-E", "CYCLES", "--python",  "rubix.py", "--",  '%.4f' % apos,  '%.4f' % bpos, "strip{:02d}.png".format(strip_number)]
      #add the machine's start time to the array
      self.start_time[machine] = time.time()
      #run the command to render the strip !!OMG SET STDOUT AND STDERR TO NULL TO SUPPRESS OUTPUT
      result = subprocess.call(com, stdout = self.null_file_handle, stderr = self.null_file_handle, shell=False)
      #add the time it took to the array (mostly so the wait function knows we're done)
      self.duration_time[machine] = time.time() - self.start_time[machine]

  
  def launch_threads(self, blender_string):
      apos = 0
      for n in range(self.num_strips):
          bpos = apos + 1.0 / float(self.num_strips)#0.05
          call_args = (n+1, blender_string, apos, bpos, n)
          
          thread = threading.Thread(
            target=self.threaded_call,
            args = call_args
          )
          thread.start()
          apos = bpos
          
  
  def threaded_ssh(self, cmd, machine, call):
      com = [cmd + " " + machine + " " + call]
      result = subprocess.call(com, stdout = self.null_file_handle, stderr = self.null_file_handle, shell=True)
      if result == 0:
          self.ssh_ok.append(machine)
      else:
          self.ssh_ok.append("FAIL")
  
  def test_ssh(self, blender_string):
      self.ssh_ok.clear()
      #copy file to the cluster
      for n in range(20):
          com = ["scp", blender_string, "username@ip_address{:02d}:".format(n+1)]
          thread = threading.Thread(target=self.threaded_ssh, args = com)
          thread.start()
      #wait for them to finish
      while len(self.ssh_ok) < 20:
          time.sleep(.05)
      ssh_start = time.time()
      self.launch_threads(blender_string)
      self.monitor_renders(ssh_start, blender_string)
      self.ssh_ok.clear()
      #copy them to controller
      for n in range(20):
          com = ["scp", "username@ip_address{:02d}:strip*.png".format(n+1), "/tmp/"]
          thread = threading.Thread(target=self.threaded_ssh, args = com)
          thread.start()
      while len(self.ssh_ok) < 20:
          time.sleep(.05)
      #flatten the images
      flatten_start = time.time()
      com = ["convert", "/tmp/strip*.png",  "-flatten", "/tmp/output.png"]
      subprocess.call(com, shell=False)
      #copy it back to main pc
      com = ["scp", "/tmp/output.png", "username@192.168.1.100:/users/username"]
      subprocess.call(com, shell=False)
      #clean up temp files from nodes
      for n in range(20):
          com = ["ssh", "username@ip_address{:02d}".format(n+1), "rm strip*.png"]
          thread = threading.Thread(target=self.threaded_ssh, args = com)
          thread.start()
              
  	  
  def main(self):

      if (len(sys.argv) == 1):
          print("No blend file supplied, exiting!\nUsage: render_farm.py <blendfile.blend>")
          return
      
      #blender_string = the blendfile name
      blender_string = sys.argv[1]
      self.test_ssh(blender_string)
      return
      
      #get the time we started the threads
      #process_start = time.time()
      
      #clear the start time and duration time arrays
      #self.start_time.clear()
      #self.duration_time.clear()
      
      #self.launch_threads(blender_string)
      
      #wait for threads to be done
      
      #self.monitor_renders(process_start, blender_string)
      
      #print("Process time: ", time.time() - process_start)
      
      #signal that we're done
      #TODO: Copy strips back from machines that aren't my rig
      #should PROBABLY do this inside the thread instead of as an extra step
      #TODO: Also add frame number as file name instead of hard coded
      print("Stitching together output file!")
      stitch_start = time.time()
      com = ["magick.exe", "c:/users/username/strips/*.png", "-flatten", "c:/users/username/images/output.png"]
      result = subprocess.call(com, shell=False)
      stitch_end = time.time() - stitch_start
      print("Time: ", stitch_end)
      
      
      #and then clean up the strips folder
      print("Cleaning up temp files...")
      com = ["del", "c:\\users\\username\\strips\\*.*", "/q"]
      result = subprocess.call(com, shell=True)
      
      return
      
      #this gets the start and end frame number in the animation
      result = blend_render_info.read_blend_rend_chunk("testme.blend")
      startx = result[0][0]
      endx = result[0][1]
      print("Startx: ", startx)
      print("Endx  : ", endx)
      return
      #break it into 20 strips
      for n in range(2):
          startx = str(n / 2.0)
          endx = str((n+1) / 2.0)
          com = ["C:\Program Files\Blender Foundation\Blender 2.82\\blender.exe", "-b", "testme.blend", "-E", "CYCLES", "--python", "blender_temp.py", "--", startx, endx, "c:/users/username/strips/"+str(n)+".png", "1"]
          result = subprocess.call(com, shell=False)
      #TODO FIX hard coded frame number lol
      com = ["magick.exe", "c:/users/username/strips/*.png", "-flatten", "c:/users/username/images/1.png"]
      result = subprocess.call(com, shell=False)
	  
	  #clean up strips dir
      com = ["del", "c:\\users\\username\\strips\\*.*", "/q"]
      result = subprocess.call(com, shell=True)


if __name__ == '__main__':
  Main().main()
