
import os
from time import sleep
from typing import Dict
from pythonosc import udp_client  

import psutil
import click

PROCESS_IGNORE_LIST = {"root"}
CURRENT_PID = os.getpid()

"""
Potentially Interested in these numerical values:
'cpu_percent', 'cpu_times', 'memory_percent', 'nice', 'num_ctx_switches', 'num_fds', 'num_threads'

cpu_times -> kernel/user

cpu usage: 0 - 200?
mem: 0 - 100 

continuous vars:
 - mem percent for top mem usage proc
 - num system procs
 - num user procs

discrete vars:
 - cpu percent for top cpu usage proc
"""



osc_client = udp_client.SimpleUDPClient("127.0.0.1", 57120)

def user_process(p_info: Dict) -> bool:
    return p_info["username"] not in PROCESS_IGNORE_LIST and p_info["pid"] != CURRENT_PID

def quantify_string(s: str, thresh: int) -> int:
    full_int = int.from_bytes(bytes(s, 'utf-8'), "big")
    while full_int-thresh > thresh:
        full_int = full_int // 10
    return full_int


def poll_processes(poll_rate: int=50):
    tick = 0
    previous_top_proc_by_num = ""
    unique_user_proc_names_prev = None
    cpu_usage_history = []

    try:
        while True:
            processes = list(psutil.process_iter())
            print(f"len: {len(processes)}")
            num_active_system_procs = 0
            num_active_user_procs = 0

            user_mem_pct = 0
            user_cpu_pct = 0

            cleaned_processes = {}
            unique_user_proc_names_current = set()
            for p in processes:
                try:
                    p_info = p.as_dict(attrs=["cpu_percent", "cpu_times", "memory_percent", "nice", "num_threads", "num_fds", "username", "pid", "name"])
                    if p_info['cpu_times'] is None:
                        raise AttributeError
                except psutil.NoSuchProcess as e:
                    print(f"Can't find {e.name}. Skipping.")
                    continue
                except AttributeError as e:
                    print("Skipping process as attributes empty.")

                if user_process(p_info):                    
                    if p_info['name'] in cleaned_processes:
                        cleaned_processes[p_info['name']]['cpu_percent'] += p_info['cpu_percent']
                        cleaned_processes[p_info['name']]['cpu_times']['user'] += p_info['cpu_times'][0]
                        cleaned_processes[p_info['name']]['cpu_times']['kernel'] += p_info['cpu_times'][1]
                        cleaned_processes[p_info['name']]['memory_percent'] += p_info['memory_percent']
                        cleaned_processes[p_info['name']]['nice'] = max(p_info['nice'], cleaned_processes[p_info['name']]['nice'])
                        if p_info['num_fds']:
                            if cleaned_processes[p_info['name']]['num_fds']: 
                                cleaned_processes[p_info['name']]['num_fds'] += p_info['num_fds']
                            else:
                                cleaned_processes[p_info['name']]['num_fds'] = p_info['num_fds']

                        cleaned_processes[p_info['name']]['num_threads'] += p_info['num_threads']
                        cleaned_processes[p_info['name']]['total_num_procs'] += 1
                        user_mem_pct += p_info['memory_percent']
                        user_cpu_pct += p_info['cpu_percent']

                    else:
                        
                        cleaned_processes[p_info['name']] = {'cpu_percent': p_info['cpu_percent'], 
                                                            'cpu_times': {'user': p_info['cpu_times'][0], 'kernel': p_info['cpu_times'][1]}, 
                                                            'memory_percent': p_info['memory_percent'], 'nice': p_info['nice'], 
                                                            'num_fds': p_info['num_fds'], 'num_threads': p_info['num_threads'], 
                                                            'total_num_procs': 0}
                        unique_user_proc_names_current.add(p_info['name'])

                    num_active_user_procs += 1       
                else:
                    num_active_system_procs += 1

            # TODO: if we're only keeping track of top proc then we should do it manually instead of sorting
            procs_by_count = sorted(cleaned_processes.items(), key=lambda x: x[1]['total_num_procs'], reverse=True)
            print(f"Top Proc by count: {procs_by_count[0][0]} with {procs_by_count[0][1]['total_num_procs']} procs")

            procs_by_cpu = sorted(cleaned_processes.items(), key=lambda x: x[1]['cpu_percent'], reverse=True)
            procs_by_mem = sorted(cleaned_processes.items(), key=lambda x: x[1]['memory_percent'], reverse=True)
            print(f"Top Proc by CPU: {procs_by_cpu[0][0]} with {procs_by_cpu[0][1]['cpu_percent']}% cpu usage")
            print(f"Top Proc by Mem: {procs_by_mem[0][0]} with {procs_by_mem[0][1]['memory_percent']}% ram usage")
            print(f"Num System Procs: {num_active_system_procs}\nNum Clean User Procs: {len(cleaned_processes)}\n")
            print(f"Total User CPU: {user_cpu_pct}")

            if unique_user_proc_names_prev:
                for proc in unique_user_proc_names_current - unique_user_proc_names_prev:
                    print(f"New Proc: {proc}")
                    osc_client.send_message("/new_proc", quantify_string(proc, 1000))

            if previous_top_proc_by_num != procs_by_count[0][0]:
                previous_top_proc_by_num = procs_by_count[0][0]
                
                print(f"top proc replaced: {previous_top_proc_by_num}")
                osc_client.send_message("/new_top_proc", quantify_string(previous_top_proc_by_num, 1000))

            if len(cpu_usage_history) > 0 and tick % 5 == 0:
                # average cpu usage
                average_cpu_usage = sum(cpu_usage_history)/len(cpu_usage_history)
                print(f"Average CPU Usage: {average_cpu_usage}")
                osc_client.send_message("/top_cpu_usage", average_cpu_usage)
                cpu_usage_history.clear()
            else:
                cpu_usage_history.append(procs_by_cpu[0][1]['cpu_percent'])

            # osc_client.send_message("/top_cpu_usage", procs_by_cpu[0][1]['cpu_percent'])
            osc_client.send_message("/top_mem_usage", procs_by_mem[0][1]['memory_percent'])
            osc_client.send_message("/system", [num_active_system_procs, user_cpu_pct])
            
            tick = tick+1 if tick < 100 else 0
            unique_user_proc_names_prev = unique_user_proc_names_current
            sleep(poll_rate/1000)
    finally:
        osc_client.send_message("/stop_all", None)

@click.command()
@click.option("--poll-rate", default=50, help="How fast to poll processes in ms")
def main(poll_rate):
    """Explore the sonic world of your computer. Associated supercollider file must be running."""
    poll_processes(poll_rate=poll_rate)

if __name__ == "__main__":
    main()