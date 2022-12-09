
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

def user_process(p_info: Dict) -> bool:
    return p_info["username"] not in PROCESS_IGNORE_LIST and p_info["pid"] != CURRENT_PID

def poll_processes(poll_rate: int=5):
    cleaned_processes = {}

    while True:
        processes = list(psutil.process_iter())
        num_active_system_procs = 0

        for p in processes:
            try:
                p_info = p.as_dict()
            except psutil.NoSuchProcess as e:
                print(f"Can't find {e.name}. Skipping.")
                continue

            if user_process(p_info):
                if p_info['name'] in cleaned_processes:
                    cleaned_processes[p_info['name']]['cpu_percent'] += p_info['cpu_percent']
                    cleaned_processes[p_info['name']]['cpu_times']['user'] += p_info['cpu_times'][0]
                    cleaned_processes[p_info['name']]['cpu_times']['kernel'] += p_info['cpu_times'][1]
                    cleaned_processes[p_info['name']]['memory_percent'] += p_info['memory_percent']
                    cleaned_processes[p_info['name']]['nice'] = max(p_info['nice'], cleaned_processes[p_info['name']]['nice'])
                    cleaned_processes[p_info['name']]['num_fds'] += p_info['num_fds']
                    cleaned_processes[p_info['name']]['num_threads'] += p_info['num_threads']
                else:
                    cleaned_processes[p_info['name']] = {'cpu_percent': p_info['cpu_percent'], 
                                                        'cpu_times': {'user': p_info['cpu_times'][0], 'kernel': p_info['cpu_times'][1]}, 
                                                        'memory_percent': p_info['memory_percent'], 'nice': p_info['nice'], 
                                                        'num_fds': p_info['num_fds'], 'num_threads': p_info['num_threads']}
            else:
                num_active_system_procs += 1

        # print(f"Num System Procs: {num_active_system_procs}\nNum Clean User Procs: {len(cleaned_processes)}\n")
                
        osc_client.send_message("/system", num_active_system_procs)
        sleep(poll_rate/1000)
        

if __name__ == "__main__":
    poll_processes()