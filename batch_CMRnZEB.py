#!/usr/bin/env python3

# Last changed: 15/08/2020
# Status: usable.
#
# Script runs a set of simulations for the CMRnZEB model.
#
# The script as well as the corresponding function labraries are expected 
# to be located in the model folder. The working directory is changed
# to <modelpath>/cfg from there.
#
import os
import shutil
import sys
import math
import subprocess
import humanfriendly
from datetime import datetime
from datetime import timedelta

# Give position of ESP-r text mode function libraries and import.
sys.path.append(os.path.join(os.path.dirname(__file__)))
import espr_sim
import espr_ms_sim
import espr_res

# Set working directory to cfg folder.
os.chdir(os.path.join(os.path.dirname(__file__),'cfg'))
#print('\tNow in working directory ' + os.getcwd() + '.')

# Check if "results mode"
#print('** len(sys.argv)= ' + str(len(sys.argv)) + ';')
if (len(sys.argv) > 1) is True:
    SIMU = False
else:
    SIMU = True

# Set clean mode.
RUNCLEAN=True

# Enter configuration file names without extension.
config_list = ["CMRnZEB"]

# Enter connections file name without extension.
cnn_file = "CMRnZEB"

# Enter control file names without extension.
#ctl_list = ['nc1', 'nc2', 'ac1', 'ac2', 'ac3']
ctl_list = ['nc1']

# Simulation periods master list.
PM = { 'sum'     : {'FD' : "16", 'FM' : "04", 'TD' : "15", 'TM' : "10", 'PP' : "20" },
       'win1'    : {'FD' : "01", 'FM' : "01", 'TD' : "15", 'TM' : "04", 'PP' : "20" },
       'win2'    : {'FD' : "16", 'FM' : "10", 'TD' : "31", 'TM' : "12", 'PP' : "20" },
       'year'    : {'FD' : "01", 'FM' : "01", 'TD' : "31", 'TM' : "12", 'PP' : "20" },
       'trnsum'  : {'FD' : "01", 'FM' : "04", 'TD' : "15", 'TM' : "06", 'PP' : "20" },
       'trnwin'  : {'FD' : "15", 'FM' : "08", 'TD' : "31", 'TM' : "10", 'PP' : "20" },
       'testsum' : {'FD' : "27", 'FM' : "07", 'TD' : "05", 'TM' : "08", 'PP' :  "5" },
       'testwin' : {'FD' : "27", 'FM' : "01", 'TD' : "05", 'TM' : "02", 'PP' :  "5" },
       'janfeb'  : {'FD' : "01", 'FM' : "01", 'TD' : "28", 'TM' : "02", 'PP' : "20" },
       'test'    : {'FD' : "15", 'FM' : "02", 'TD' : "17", 'TM' : "02", 'PP' :  "2" }}

# Set desired simulation list.
#period_list = ['janfeb']
period_list = ['test']

# Enter PCM special materials options. A spm file is always active
# due to explicit PV definition.
#spm_list = ['noPCM', 'RT26']
spm_list = ['noPCM']

# Obstruction dimensions for south-facing windows, default is "no shading".
OBS = { '002'  : {'width' : "16.25", 'depth' : "0.02", 'height' : "0.05" },
        '100'  : {'width' : "16.25", 'depth' : "1.00", 'height' : "0.05" },
        '150'  : {'width' : "16.25", 'depth' : "1.50", 'height' : "0.05" }}

def_obs = '002'

obs_list = ['002', '100', '150']
#obs_list = ['002']

# Enter Constructions master lists and set respective default
# constructions for roll-back after simulation.
# Ceiling constructions.
CCM = { 'CT_Ceiling'   : {'cat' : "g", 'con' : "a"},
        'CT_Ceil_20mm' : {'cat' : "g", 'con' : "c"},
        'CT_Ceil_50mm' : {'cat' : "g", 'con' : "e"},
        'CT_Ceil_100mm': {'cat' : "g", 'con' : "g"}}

# Default ceiling construction.
def_ceil = 'CT_Ceiling'

# Abbreviations for ceiling constructions for file names.
CCshort = { 'CT_Ceiling'   : "c000",
            'CT_Ceil_20mm' : "c020",
            'CT_Ceil_50mm' : "c050",
            'CT_Ceil_100mm': "c100"}

# Wall constructions.
WCM = { 'CT_Ext_Wall'  : {'cat' : "a", 'con' : "a"},
        'CT_EW_aerated': {'cat' : "a", 'con' : "b"},
        'CT_EW_brick'  : {'cat' : "a", 'con' : "c"},
        'CT_EW_PCM'    : {'cat' : "a", 'con' : "d"},
        'CT_EW_Wood'   : {'cat' : "a", 'con' : "e"}}

# Default wall construction.
def_wall = 'CT_Ext_Wall'

# Abbreviations for wall constructions for file names.
WCshort = { 'CT_Ext_Wall'   : "cw",
            'CT_EW_aerated' : "aw",
            'CT_EW_brick'   : "bw",
            'CT_EW_PCM'     : "pw",
            'CT_EW_Wood'    : "ww" }

# Create construction lists. 
#ceiling_list = ['CT_Ceiling', 'CT_Ceil_20mm', 'CT_Ceil_50mm', 'CT_Ceil_100mm']
#ceiling_list = ['CT_Ceil_20mm']
ceiling_list = ['CT_Ceiling']

#wall_list    = ['CT_Ext_Wall', 'CT_EW_aerated', 'CT_EW_brick', 'CT_EW_Wood']
#wall_list    = ['CT_EW_aerated']
wall_list    = ['CT_Ext_Wall']

# Set building timesteps per hour 'BTSTEP' and plant time steps per
# building time step 'PTSTEP' as global values.
BTSTEP = "15"
PTSTEP = "3"

# Define desired PMV base data.
PMV = { 'CFno': {'clo' : "0.5", 'met' : "1.0", 'veloc' : "0.1"},
        'CFlo': {'clo' : "0.5", 'met' : "1.0", 'veloc' : "0.6"},
        'CFhi': {'clo' : "0.5", 'met' : "1.0", 'veloc' : "1.3"}}

CFlist = ['CFno', 'CFlo', 'CFhi']

# Run simulation cases.
cnt = 0
config = 'CMRnZEB'

for obs in obs_list:

    # Set switch for PCM / no PCM in model.
    if "noPCM" in config:
        pcm = False
    else:
        pcm = True

    # Loop through control options.
    for ctl in ctl_list:

        # Loop through simulation period options.
        for per in period_list:

            # Loop through special materials options.
            for spm in spm_list:

                spm_file = "CT_" + spm

                # Loop through ceiling and wall construction options.
                for ccon in ceiling_list:

                    old_cclass = CCM[def_ceil]['cat']  
                    old_ccon   = CCM[def_ceil]['con']
                    
                    for wcon in wall_list:
                        
                        old_wclass = WCM[def_wall]['cat']  
                        old_wcon   = WCM[def_wall]['con']  

                        # File name for current simulation set
                        variant = str(config + "_" + obs + "_" + ctl + "_" + CCshort[ccon] + "_"
                                       + WCshort[wcon] + "_" + spm + "_" + per)

                        # Bookkeeping for simulation duration message.
                        if (cnt == 0) is True:
                             # Store starttime for series.
                             now0 = datetime.now()
                             now  = now0
                             # Calculate total number of variants.
                             numvars = len(obs_list)*len(ctl_list)*len(period_list) \
                                      *len(spm_list)*len(ceiling_list)*len(wall_list)
                             remaining = 86400
                             rd = -2
                        else:
                        # Get current datetime and calculate difference.
                            now = datetime.now()
                            averagetime = (now-now0).total_seconds() / cnt
                            remaining = (numvars-cnt)*averagetime
                            rd = -1*min(math.floor(math.log10(remaining)),2)

                        cnt = cnt + 1

                        # Message about current simulation set
                        print("\n")
                        print("\t=========================================================================")
                        if SIMU is True:
                            print("\tSimulating case " + str(cnt) + "/" + str(numvars) + ": " \
                                                       + variant + ", " + now.strftime("%d/%m %H:%M:%S"))
                            print("\tThe remaining time is approximately " \
                                                       + humanfriendly.format_timespan(round(remaining,rd)))
                        else:
                            print("\tEvaluating case " + str(cnt) + "/" + str(numvars) + ": " + variant)
                            print("\tThe remaining time is approximately " \
                                                       + humanfriendly.format_timespan(round(remaining,rd)))
                        print("\t=========================================================================")
                        print("\twith obstructions          : " + obs)
                        print("\twith control file          : " + ctl + ".ctl")
                        if pcm is True:
                            print("\twith PCM                   : " + spm)
                        print("\tusing ceiling & wall       : " + ccon + " & " + wcon)
                        print("\tfor period                 : " + per + "\n")

                        if SIMU is True:
                            # Set control and spm files from ctl_list and spm_list.
                            espr_sim.set_ctl(config, ctl)
                            espr_sim.set_spm(config, cnn_file, spm_file)

                            # Conditionall set obstructions, where
                            # d - Bedroom_1, f - Salon and i - Bedroom_2.
                            if (obs == def_obs) is False:
                               espr_sim.set_obs_dim(config, 'd', 'e', **OBS[obs])
                               espr_sim.set_obs_dim(config, 'f', 'e', **OBS[obs])
                               espr_sim.set_obs_dim(config, 'i', 'e', **OBS[obs])

                            # Conditionally set ceiling construction.
                            if (ccon == def_ceil) is False:
                                espr_ms_sim.set_con(config, cnn_file, def_ceil,
                                                    old_cclass, old_ccon,
                                                    CCM[ccon]['cat'],CCM[ccon]['con'])

                            # Conditionally set wall construction.
                            if (wcon == def_wall) is False:
                                espr_ms_sim.set_con(config, cnn_file, def_wall,
                                                    old_wclass, old_wcon,
                                                    WCM[wcon]['cat'], WCM[wcon]['con'])
    
                            # Remove old results and contents files from the cfg-directory.
                            espr_sim.remove_results(variant, 'STALE')

                            # Start current simulation set
                            espr_sim.qa_report(config, variant)
                            espr_sim.simulate(2, config, variant, BTSTEP, 0, **PM[per])
                        
                            # Extract results via res.
                            for CF in CFlist:
                                espr_res.res_PMV(variant, 'f', **PMV[CF])

                            # Remove results files if disc space is an issue.
                            if RUNCLEAN is True:
                                espr_sim.remove_results(variant, 'RUNCLEAN')

                            # Rename H3K-output.csv to <variant>.csv, create
                            # subdirectories for current simulation set and
                            # move all corresponding files there.
                            espr_sim.move_files(variant)

                        # Evaluations via R.
                        cmd='/usr/local/bin/Rscript ../plot_mult_R_evaluations.r' \
                             + ' ' + variant + '/' + variant + '.csv' \
                             + ' ' + str(BTSTEP) + ' ' + now.strftime("%d.%m_%H:%M:%S") \
                             + ' ' + espr_sim.list_of_files(variant, 'dat')
                        subprocess.call(cmd, shell=True)


                        # Set wall constructions back to default.
                        if SIMU is True:
                            if (wcon == def_wall) is False:
                                espr_ms_sim.set_con(config, cnn_file, wcon,
                                                    WCM[wcon]['cat'], WCM[wcon]['con'],
                                                    old_wclass, old_wcon)
                    # wcon-loop closed
                    
                    # Set ceiling constructions back to default.
                    if SIMU is True:
                        if (ccon == def_ceil) is False:
                            espr_ms_sim.set_con(config, cnn_file, ccon,
                                                CCM[ccon]['cat'],CCM[ccon]['con'],
                                                old_cclass, old_ccon)
                # ccon-loop closed
                
            # spm-loop closed

        # period-loop closed

    # ctl-loop closed

    # Set obstruction dimension back to default.
    if SIMU is True:
        if (obs == def_obs) is False:
          espr_sim.set_obs_dim(config, 'd', 'e', **OBS[def_obs])
          espr_sim.set_obs_dim(config, 'f', 'e', **OBS[def_obs])
          espr_sim.set_obs_dim(config, 'i', 'e', **OBS[def_obs])

        # Final cleanup.
        espr_sim.move_files(variant)

# obs-loop closed
