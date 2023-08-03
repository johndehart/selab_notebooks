def salute():
  print("Hello PMASE... this is SysMLv2!!!")

def getModels():
# automatically extracts all sysml models and model names in the current folder
# model list starts at [0]
# add 2 new cells for each sysml model you wish to display
# How to use: Start an SoS kernel
################################################################################
# cell1(python3)-  %load getModels.py
# cell2(SoS)-      %get model model_name --from Python3
# cell3(SysML)-    %expand
#                  {model[x]}
# cell4(SysML):    %expand
#                  %viz {model[x]}
################################################################################
    import glob
    import os
    model_files = glob.glob("*.sysml")
    model = []
    model_name = []
    for file_path in model_files:
        with open(file_path) as f_input:
            model.append(f_input.read())
    for mod in model:
        model_name.append(mod.split(' ')[1])
    print(len(model), "model(s) retrieved...")
    return model, model_name

def getReqs(fileName, response=''):
# dumb script to extract sysml2 requirments from a .sysml file
################################################################################
# read the file into a list of lines
# and extract the lines that are actual requirments
################################################################################

    import pandas as pd
    pd.set_option('display.max_colwidth', 0) # set the colum widths to whatever necessary
    
    d = {}
    #d['xyz'] = 42
    #print(d['xyz'])
    
    # build local variables from the response data frame
    ### this was a tough one... locals() and globals() do not work wihtin a function
    ### much easier to use a dict and then convert to variables
    ### still a pia since the system will not print the raw variable????
    if len(response) > 0:
        # build the dict
        for index, row in response.iterrows():
            d[row[0]] = row[1]
        
        for k, v in d.items():
            exec("%s = %s" % (k, v))
            locals()[k]=v
        
        #working
        print(eval('asrt'))
        
    # define data frame
    reqDf = pd.DataFrame(columns=['Class', 'ID', 'Name', 'Doc', 'Type', 'Constraint','Actual','Delta','Pass'])

    # array to store the lines identifed with the keyword
    reqLines = []

    # set the keyword to extract (move to array)
    keyWord_A = 'requirement'
    keyWord_B = 'attribute'
    keyWord_C = 'doc'
    keyWord_D = 'constraint'
    
    fileName = fileName
    # from IPython.display import FileLink, FileLinks
    # fileName = FileLink('/ASE6104/Users/Brian Ritchey/Req_Test_W_Attributes_V2.ipynb')

    # set row styles
    def change_colour(val):
       return ['background-color: red' if x < 40  else ('' if x==440 else 'background-color: green') for x in val]

    # set column aligment
    def left_align(df):
        left_aligned_df = df.style.set_properties(**{'text-align': 'left'})
        left_aligned_df = left_aligned_df.set_table_styles(
            [dict(selector='th', props=[('text-align', 'left')])]
        )
        return left_aligned_df
    
    # Read in the file name
    with open(fileName,'r') as f:
        lines = f.read().split("\n")
        
    # loop through each line and identify lines with match to keyWord
    for i, line in enumerate(lines):
        # use in line.split() to get exact match (finds 'test' not 'tests')
        # use in line to get match (finds 'test' in 'tests')
        
        if keyWord_D in line.split():
            docKeyStart = "{"
            docKeyEnd = "}"
            docRow = (line.split(docKeyStart))[1].split(docKeyEnd)[0]
            reqDf.loc[len(reqDf.index)-1,"Constraint"] = docRow
            dat = reqDf.loc[len(reqDf.index)-1,"Pass"] = eval(eval('reqDf.loc[len(reqDf.index)-1,"Constraint"]'))
            ##print(reqDf.loc[len(reqDf.index)-1,"Constraint"])
            ##dat = eval(eval('reqDf.loc[len(reqDf.index)-1,"Constraint"]'))
            #print(dat)
            continue 
        
        if keyWord_C in line.split():
            docKeyStart = "/* "
            docKeyEnd = " */"
            docRow = (line.split(docKeyStart))[1].split(docKeyEnd)[0]
            reqDf.loc[len(reqDf.index)-1,"Doc"] = docRow
            continue    
            
        #print(reqLines)
        if keyWord_B in line.split(): # or word in line to search for any words
            tmpRow = line.split()
            if len(tmpRow) > 3: # if variable is assigned
                reqDf.loc[len(reqDf.index)] = [tmpRow[0],'',tmpRow[1][:-1],'',tmpRow[2][:-1],'',tmpRow[3][:-1],'',''] #reqDf.eval(tmpRow[1][:-1])
                if len(response) > 0:
                    val = float(reqDf[reqDf['Name'].str.match(tmpRow[1][:-1])]['Actual'].values[0])
                    print(tmpRow[1][:-1], val)
                    exec(tmpRow[1][:-1] + '=val') # this line throws the requirments attribute varaibles into memory
                    reqDf.loc[len(reqDf.index)-1] = [tmpRow[0],'',tmpRow[1][:-1],'',tmpRow[2][:-1],'',tmpRow[3][:-1],'',''] #
                
            else:
                reqDf.loc[len(reqDf.index)] = [tmpRow[0],'',tmpRow[1][:-1],'',tmpRow[2][:-1],'','','TBD','']
            continue    
        
        if keyWord_A in line.split(): # or word in line to search for any words
            tmpRow = line.split()
            reqDf.loc[len(reqDf.index)] = [tmpRow[0],tmpRow[3].strip("'"),tmpRow[4][:-1],'','','','','','']
            continue    
        
        # add in the resposne data to the table
        if len(response) > 0:
            for index, row in response.iterrows():
                reqDf['Actual'][reqDf['Name'].str.match(response.iloc[index,0])] = response.iloc[index,1]
                exec('response.iloc[index,0] = response.iloc[index,0]', locals())
         
    # performing two style operations on the table
    dfStyler = reqDf.style.set_properties(**{'text-align': 'left'})
    dfStyler.set_table_styles([dict(selector='th', props=[('text-align', 'left')])])
    
    return dfStyler

def getReqsString(model_string): #not working
# dumb script to extract sysml2 requirments from a .sysml file
################################################################################
# read the file into a list of lines
# and extract the lines that are actual requirments
################################################################################
    import io
    
    import pandas as pd
    pd.set_option('display.max_colwidth', 0) # set the colum widths to whatever necessary

    # define data frame
    reqDf = pd.DataFrame(columns=['Class', 'ID', 'Name', 'Doc', 'Type', 'Constraint','Actual','Delta','Pass'])

    # array to store the lines identifed with the keyword
    reqLines = []

    # set the keyword to extract (move to array)
    keyWord_A = 'requirement'
    keyWord_B = 'attribute'
    keyWord_C = 'doc'
    keyWord_D = 'constraint'
    
    #fileName = model_string
    # from IPython.display import FileLink, FileLinks
    # fileName = FileLink('/ASE6104/Users/Brian Ritchey/Req_Test_W_Attributes_V2.ipynb')

    # set row styles
    def change_colour(val):
       return ['background-color: red' if x < 40  else ('' if x==440 else 'background-color: green') for x in val]

    # set column aligment
    def left_align(df):
        left_aligned_df = df.style.set_properties(**{'text-align': 'left'})
        left_aligned_df = left_aligned_df.set_table_styles(
            [dict(selector='th', props=[('text-align', 'left')])]
        )
        return left_aligned_df
    
    # Read in the file name
    #with open(fileName,'r') as f:
    #    lines = f.read().split("\n")
        
    # loop through each line and identify lines with match to keyWord
    
    for i, line in enumerate(io.StringIO(model_string)):
    #print(repr(line))
    #for i, line in enumerate(lines):
        # use in line.split() to get exact match (finds 'test' not 'tests')
        # use in line to get match (finds 'test' in 'tests')
        
        if keyWord_D in line.split():
            docKeyStart = "{"
            docKeyEnd = "}"
            docRow = (line.split(docKeyStart))[1].split(docKeyEnd)[0]
            reqDf.loc[len(reqDf.index)-1,"Constraint"] = docRow
            continue 
        
        if keyWord_C in line.split():
            docKeyStart = "/* "
            docKeyEnd = " */"
            docRow = (line.split(docKeyStart))[1].split(docKeyEnd)[0]
            reqDf.loc[len(reqDf.index)-1,"Doc"] = docRow
            continue    
            
        #print(reqLines)
        if keyWord_B in line.split(): # or word in line to search for any words
            tmpRow = line.split()
            reqDf.loc[len(reqDf.index)] = [tmpRow[0],'',tmpRow[1][:-1],'',tmpRow[2][:-1],'','',"TBD",'']
            continue    
        
        if keyWord_A in line.split(): # or word in line to search for any words
            tmpRow = line.split()
            reqDf.loc[len(reqDf.index)] = [tmpRow[0],tmpRow[3].strip("'"),tmpRow[4][:-1],'','','','',"NA",'']
            continue    
    
    # performing two style operations on the table
    dfStyler = reqDf.style.set_properties(**{'text-align': 'left'})
    dfStyler.set_table_styles([dict(selector='th', props=[('text-align', 'left')])])
 
    return dfStyler

def getParts(fileName):
# dumb script to extract sysml2 parts from a .sysml file
################################################################################
# read the file into a list of lines
# and extract the lines that are actual requirments
################################################################################
     
    return

def valReqs():
# fucntion to validate the reqs table
# the getReqs should be simplified to just show reqs only
    return