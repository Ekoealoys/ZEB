#!/usr/bin/env python3

# Last changed: 04/08/2020
# Status: Should work ...
# Module contains following functions for ESP-r:
#
# 13:  def qa_report(config, variant):
#            Create QA report.
# 59:  def simulate(mode, config, variant, start_day, start_month, end_day, end_month, pre_days, time_steps):
#            Simulate a model, building domain, only.
# 181: def set_ctl(config, ctl_file):
#            Set the control file to "ctl_file".
# 228: def set_spm(config, cnn_file, spm_file):
#            Set special materials file to "spm_file".
# 303: def set_obs_dim(config, zone, obs, width, depth, height):
#            Set obstruction dimensions.

"""
Module contains functions for ESP-r scripts and auxiliary functions for
batch running of simulations.
"""

def qa_report(config, variant):
    """Create QA report.

    arguments:
    [1] configuration file name without extension
    [2] variant name (ctl, con, mat)"""

    from subprocess import run

    print("\tQA report         : " + variant + ".contents")

    # Creating QA report
    args = [
            "prj",
            "-file", config + ".cfg",  # executable file
            "-mode", "text",  # opens file in mode text
            ]

    cmd = bytes("m\n"  # browse/ edit/ simulate
                "u\n"  # QA reporting
                "N\n"  # Format the contents report in Markdown? [Y/N]
                "a\n"  # site info (toggle)
                "c\n"  # model context (toggle)
                "d\n"  # controls (toggle)
                "g\n"  # zone selection
                "*\n"  # all items
                "-\n"  # exit menu
                "m\n"  # file names (toggle)
                ">\n"  # QA report to
                + variant + ".contents\n"  # model contents file
                "!\n"  # generate QA report
                "-\n"  # exit menu
                "-\n"  # exit this menu
                "-\n-",  # exit Project Manager
                encoding="utf-8")

    f = open(variant + "_qa.scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs prj (args), executes commands (cmd), writes scratch file (f)


""" ============================================
    Auxiliary functions for simulation domain management """
def list_dms(dms, variant):
    switcher = {
        1: "\tbuilding results  : " + variant + ".res",
        2: "\tbuilding results  : " + variant + ".res\n" +
           "\tair flow results  : " + variant + ".mfr",
        3: "\tbuilding results  : " + variant + ".res" +
           "\tplant results     : " + variant + ".plr",
        4: "\tbuilding results  : " + variant + ".res\n" +
           "\tplant results     : " + variant + ".mfr\n" +
           "\tair flow results  : " + variant + ".plr"
    }
    return switcher.get(dms, "Error in dms")

def rf_dms(dms, variant):
    switcher = {
    1: bytes("" + variant + ".res\n",  # zone results library name
             encoding= 'utf-8' ),
    2: bytes("" + variant + ".res\n"  # zone results library name
             "" + variant + ".mfr\n",  # mass flow results library name
             encoding= 'utf-8' ),
    3: bytes("" + variant + ".res\n"  # zone results library name
             "" + variant + ".plr\n",  # plant results library name
             encoding= 'utf-8' ),
    4: bytes("" + variant + ".res\n"  # zone results library name
             "" + variant + ".mfr\n"  # plant results library name
             "" + variant + ".plr\n",  # mass flow results library name
             encoding= 'utf-8' ),
    }
    return switcher.get(dms, "Error in dms - rf")

def ts_dms(dms, BTSTEP, PTSTEP):
    switcher = {
    1: bytes("" + str(BTSTEP) + "\n",  # building time-steps (per hour)
             encoding= 'utf-8' ),
    2: bytes("" + str(BTSTEP) + "\n",  # building time-steps (per hour)
             encoding= 'utf-8' ),
    3: bytes("" + str(BTSTEP) + "\n"   # building time-steps (per hour)
             "" + str(PTSTEP) + "\n",  # plant time-steps (per hour)
             encoding= 'utf-8' ),
    4: bytes("" + str(BTSTEP) + "\n"   # building time-steps (per hour)
             "" + str(PTSTEP) + "\n",  # plant time-steps (per hour)
             encoding= 'utf-8' ),
    }
    return switcher.get(dms, "Error in dms - ts")
""" End auxiliary functions 
    ============================================= """    


def simulate(dms, config, variant, BTSTEP, PTSTEP, FD, FM, TD, TM, PP):
    """Function runs simulation for model with dms domains involved.

    Required output files depending on simulation mode.
    1 building only, .res
    2 building and afn, .res, .mfr
    3 building and plant, .res, .plr
    4 building, afn and plant, .res, .plr, .mfr
    ... (eln, ??)

    Arguments:
    [1]      key for domains in model
    [2]      configuration file name without extension
    [3]      variant name (ctl, con, mat)
    [4]      number of days for start-up period duration
    [5]      building simulation time steps per hour
    [6]      plant time steps per building time step
    [7 to 10] start- and end dates for simulation period via dict
    """

    from subprocess import run

    print("\tRun bps with      : " + config + ".cfg")
    print(list_dms(dms,variant))
    print("\tSimulation period : " + FD + "." + FM + ". to "
          + TD + "." + TM + ". with startup " + PP + " days.")

    # Running Simulation
    args = [
        "bps",
        "-file", config + ".cfg",  # executable file (should be passed as variable from run_all)
        "-mode", "text",  # opens file in mode text
    ]

    """
    Build command for text mode.
    """
    cmd1 = bytes("\n"  # skip "model configuration file?"
                 "c\n",  # initiate simulation
                 encoding="utf-8")
    
    cmd2 = rf_dms(dms, variant)
    
    cmd3 = bytes("" + FD + " " + FM + "\n"  # start day & month (DD MM)
                 "" + TD + " " + TM + "\n"  # end day & month (DD MM)
                 "" + PP + "\n",  # start-up period duration (days)
                 encoding="utf-8")

    cmd4 = ts_dms(dms, BTSTEP, PTSTEP)

    cmd5 = bytes("N\n"  # hourly results integration? [Y/N]
                 "s\n"  # commence simulation
                 "Run:" + variant + "\n"  # result-set description
                 "Y\n"  # continue with simulation? [Y/N]
#                 "Y\n"  # use suggested control file [Y/N]
                 "Y\n"  # save simulation results? [Y/N]
                 "-\n"  # exit menu
                 "-",   # quit module
                 encoding="utf-8")

    cmd = cmd1.decode('utf-8')   \
          + cmd2.decode('utf-8') \
          + cmd3.decode('utf-8') \
          + cmd4.decode('utf-8') \
          + cmd5.decode('utf-8')
    
    cmd = cmd.encode('utf-8')

    f = open(variant + "_bps.scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs bps (args), executes commands (cmd), writes scratch file (f)

    # Postprocessing
    for line in open(variant + "_bps.scratch"):
        if "Simulation completed" in line:
            print("\n\t" + line + "\n")
#        if "XML postprocessor cpu runtime" in line:
#            print(line)


def set_ctl(config, ctl_file):
    """Function sets control file in .cfg of model.

    arguments:
    [1] configuration file name without extension
    [2] control file name without extension"""

    from subprocess import run

    print("\tSet control file  : " + ctl_file + ".ctl")

    # Setting control file
    args = [
            "prj",
            "-file", config + ".cfg",  # executable file
            "-mode", "text",  # opens file in mode text
            ]

    cmd = bytes("m\n"  # browse/ edit/ simulate
                "j\n"  # controls: zones
                "../ctl/" + ctl_file + ".ctl\n"  # control file?
                "-\n"  # exit this menu
                "Y\n"  # ctl-functions have not yet been associated w/ zones. exit anyway? [Y/N]
                "Y\n"  # save changes to control file? [Y/N]
                "Y\n"  # overwrite this file? [Y/N]
                "-\n"  # exit this menu
                "-\n-",  # exit Project Manager
                encoding="utf-8")

    f = open(config + "_set_" + ctl_file + ".scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs prj (args), executes commands (cmd), writes scratch file (f)


def set_spm(config, cnn_file, spm_file):
    """Function sets special material

    Arguments:
    [1] configuration file name without extension
    [2] connections file name without extension
    [3] special materials file name without extension"""

    from subprocess import run

    print("\tSet spm file      : " + spm_file + ".spm")

    # Setting SPM-file
    args = [
            "prj",
            "-file", config + ".cfg",  # executable file
            "-mode", "text",  # opens file in mode text
            ]

    cmd = bytes("m\n"  # browse/ edit/ simulate
                "c\n"  # composition
                "n\n"  # active materials
                "Y\n"  # does a special components file exist? [Y/N]
                "../dbs/" + spm_file + ".spm\n"  # special components filename?
                "-\n"  # exit
                "-\n"  # exit this menu
                "!\n"  # save model
                + config + ".cfg\n"  # update system configuration file?
                + cnn_file + ".cnn\n"  # surface connections file name? 
                "-\n"  # exit this menu
                "-\n-",  # exit Project Manager
                encoding="utf-8")

    f = open(config + "_set_" + spm_file + ".scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs prj (args), executes commands (cmd), writes scratch file (f)

def set_plant(config, plant, plant_db):
    """ Script changes plant network file in .cfg.
    
    Arguments:
    1. configuration root file name
    2. plant root file name
    3. plant component database used (with path)"""

#[ ! -f ../nets/${PLANT}.pln ] && echo " ** ERROR ** Plant file inexistant!"
#[ ! -f ${PLANTDB} ] && echo " ** ERROR ** Plantdb inexistant!"

    print("   In " + config + ", setting plant file to: " + plant + "... ")

    args = [
            "prj",
            "-file", config + ".cfg",  # executable file
            "-mode", "text",  # opens file in mode text
            ]
    
    cmd = bytes("m\n"  # browse/edit/simulate
                "d\n"  # plant & systems
                "b\n"  # plant model? (b explicit)
                "../nets/" + plant + ".pln\n"
                "y\n"  # Use or modify?
                "n\n"  # Display synopsis
                + plant_db + "\n"
                "-\n"  # Exit
                "y\n"  # save changes
                "../nets/" + plant + ".pln\n"
                "y\n"  # Overwrite this file?
                "-\n"  # exit plant model selection
                "-\n"  # exit this menu
                "-\n",  # exit Project Manager
                encoding="utf-8")

    f = open(config + "_set_" + plant + ".scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs prj (args), executes commands (cmd), writes scratch file (f)


def set_obs_dim(config, zone, obs, width, depth, height):
    """ Set obstruction dimensions.

    Arguments:
     1. configuration file name (with relative path)
     2. zone
     3. obstruction entry
     4. width
     5. depth
     6. height """

    from subprocess import run

    print("\tSet obstruction dimension in zone " + zone + ".")
    print("\t\tObstruction" + obs + ", width, depth, height is " \
                            + width + ", " + depth + ", " + height + "m.")

    # Setting lam for mat
    args = [
            "prj",
            "-file", config + ".cfg",  # executable file
            "-mode", "text",  # opens file in mode text
            ]

    cmd = bytes("m\n"  # browse/edit/simulate
                "c\n"  # composition
                "a\n"  # geometry & attribution
                + zone + "\n"
                "h\n"  # solar obstruction
                "a\n"  # dimensional input
                + obs + "\n"
                "b\n"  # block W D H
                + width + " " + depth + " " + height + "\n"
                "-\n"  # exit
                "-\n"  # exit menu
                "a\n"  # recalculate (silent)
                "-\n"  # exit menu
                "-\n"  # exit menu
                "-\n"  # exit menu
                "-\n"  # exit menu
                "-\n", # quite module
                encoding="utf-8")

    f = open(config + "_set_" + zone + "_" + obs + "_obs.scratch", "w")  # creates scratch file

    run(args, input=cmd, stdout=f)  # runs prj (args), executes commands (cmd), writes scratch file (f)


##############################################
### A u x i l i a r y    f u n c t i o n s.
##############################################

def list_of_files(path,ext):
    import os
    
    file_list=''
    for f in os.listdir(path):
        if os.path.isfile(os.path.join(path, f)) and f.endswith(ext):
            file_list = file_list + ' ' + path + '/' + f
    return (file_list)

# Remove old results and contents files from the cfg-directory to
# avoid conflicts with "espr_sim.qa-report" and espr_sim.simulate"
# or to avoid disc space issues for runs with many variants ('RUNCLEAN').
def remove_results(variant, mode):
    import os

    if os.path.exists("./" + variant + ".res"):
                  os.remove("./" + variant + ".res")
    if os.path.exists("./" + variant + ".mfr"):
                  os.remove("./" + variant + ".mfr")
    if os.path.exists("./" + variant + ".plr"):
                  os.remove("./" + variant + ".plr")

    if mode == 'RUNCLEAN' is False:
        if os.path.exists("./" + variant + ".contents"):
            os.remove("./" + variant + ".contents")


# Rename H3K-output.csv to <variant>.csv, create subdirectories for
# current simulation set and move all corresponding files there.
# Also, do some cleanup.
def move_files(variant):
    import os
    import shutil

    if os.path.isdir("./" + variant) is True:
        shutil.rmtree("./" + variant)
        os.mkdir("./" + variant)
    else:
        os.mkdir("./" + variant)

    if os.path.isdir("./" + variant + "_scratchfiles") is True:
        shutil.rmtree("./" + variant + "_scratchfiles")
        os.mkdir("./" + variant + "_scratchfiles")
    else:
        os.mkdir("./" + variant + "_scratchfiles")

    files = os.listdir(os.getcwd())

    for f in files:
        if f.startswith(variant + "."):
            shutil.move(f, "./" + variant)
        elif f.endswith(".csv"):
            os.rename(f, variant + ".csv")
            shutil.move(variant + ".csv", "./" + variant)
        elif f.endswith(".dat"):
            shutil.move(f, "./" + variant)
        elif f.endswith(".scratch"):
            shutil.move(f, "./" + variant + "_scratchfiles")
        # Cleanup.
        elif f.startswith("fort."):
            os.remove(f)
        elif f.startswith("graphic."):
            os.remove(f)

#    if os.path.exists("./out.xml"):
#        shutil.move("./out.xml", "./" + variant)
#    if os.path.exists(config + ".summary"):
#        os.remove("./" + config + ".summary")
#    if os.path.exists("./out.summary"):
#        os.rename("./out.summary", config + ".summary")
#    if os.path.exists("./out.dictionary"):
#        shutil.move("./out.dictionary", "./" + variant)

def list_of_files(path,ext):
    import os

    file_list=''
    for f in os.listdir(path):
        if os.path.isfile(os.path.join(path, f)) and f.endswith(ext):
            file_list = file_list + ' ' + path + '/' + f
    return (file_list)
