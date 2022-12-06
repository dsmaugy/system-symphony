
import os
from time import sleep
from typing import Dict
from pythonosc import udp_client  

import psutil

PROCESS_IGNORE_LIST = {"root"}
CURRENT_PID = os.getpid()

"""
Potentially Interested in these numerical values:
'cpu_percent', 'cpu_times', 'memory_percent', 'nice', 'num_ctx_switches', 'num_fds', 'num_threads'

cpu_times -> kernel/user
"""

osc_client = udp_client.SimpleUDPClient("172.28.208.1", 57120)

def valid_process(p_info: Dict) -> bool:
    return p_info["username"] not in PROCESS_IGNORE_LIST and p_info["pid"] != CURRENT_PID

def poll_processes(poll_rate: int=1000):
    while True:
        processes = list(psutil.process_iter())
        cleaned_processes = {}

        for p in processes:
            p_info = p.as_dict()
            if valid_process(p_info):
                print(f"User: {p_info['username']} Application: {p_info['name']}")
                if p_info['name'] in cleaned_processes:
                    pass
                else:
                    cleaned_processes[p_info['name']] = {"cpu"}
                
        osc_client.send_message("/test", "hello")
        sleep(poll_rate/1000)
        

if __name__ == "__main__":
    poll_processes()