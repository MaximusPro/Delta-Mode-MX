import json
import matplotlib.pyplot as plt
import numpy as np
from datetime import date, time, datetime
from math import ceil
def RangeToPoints(Price1, Price2, Point):
    if float(Price1) < float(Price2):
        out = (float(Price2)-float(Price1))/float(Point)
    elif float(Price2) < float(Price1):
        out = (float(Price1)-float(Price2))/float(Point)
    else: return 0
    return out

Data = list()
JsonData = list()
with open('AnalyticsLog2023.01.06.txt', 'r') as F:
   for line in F.readlines():
      #print(line)
      if line != "\n":
        Data.append(line)
try:
    print("JsonFormat:")
    for i in range(Data.__len__()):
        JsonData.append(json.loads(Data[i]))
        print(JsonData[i])
except:
    print("JSONERROR: It can't reshape in JSON!")

   #try:
    #  FJsonLoad = json.loads(FJsonLoad)
     # print(FJsonLoad)
      #print(type(FJsonLoad))
   #except:
    #  print("JSONERROR: ...")
TakeProfitsData = []
TimesData = []
Fractal = float()
FractalsList = list()
OrderOpenPriceList = list()
for i in range(JsonData.__len__()):
    StrIndex = "Index_" + str(i)
    IndexElement = JsonData[i].get(StrIndex)
    FractalKey = list(IndexElement[0].keys())
    #print(FractalKey[0])
    if FractalKey[0] == "MaxFractal":
        FractalDict = IndexElement[0]
        if FractalDict['MaxFractal'] != 0:
            #if Fractal < FractalDict['MaxFractal']:
                Fractal = FractalDict['MaxFractal']
                FractalsList.append(Fractal)
    elif FractalKey[0] == 'MinFractal':
        FractalDict = IndexElement[0]
        if FractalDict['MinFractal'] != 0:
            #if Fractal < FractalDict['MinFractal']:
                Fractal = FractalDict['MinFractal']
                FractalsList.append(Fractal)
    IndexElement.remove(IndexElement[0])
    for k in range(IndexElement.__len__()):
        TakeProfitsData.append(IndexElement[k].get('TakeProfit'))
        TimesData.append(IndexElement[k].get('OrderOpenTime'))
        OrderOpenPriceList.append(IndexElement[k].get('OrderOpenPrice'))
    #print(type(IndexElement))
print("TakeProfits: ", TakeProfitsData)
print('OrderOpenTime: ', TimesData)
print('OrderOpenPrice: ', OrderOpenPriceList)
print('Fractal: ', Fractal)
print('FractalsList: ', FractalsList)
MaxRangesList = list()
for i in range(OrderOpenPriceList.__len__()):
    MaxFractal = 0
    for k in range(FractalsList.__len__()):
        if float(MaxFractal) < float(FractalsList[k]):
            MaxFractal = (float(FractalsList[k]))
    MaxRangesList.append(int(ceil(RangeToPoints(MaxFractal, OrderOpenPriceList[i], 0.001))))
print('MaxRangesList: ', MaxRangesList)
FirstDate = list()
SecondDate = list()
NewTimesDate = list()
for i in range(TimesData.__len__()):
    FirstDate = TimesData[i].split()
    ListDate = FirstDate[0].split(".")
    String = str()
    for r in range(ListDate.__len__()):
       if String == "":
        String = ListDate[r]
       else: String = String +  '-' + ListDate[r]
    #print("String:")
    #print(String)
    FirstDate.remove(FirstDate[0])
    FirstDate.insert(0, String)
    String = ""
    for r in range(FirstDate.__len__()):
        if String == "":
            String = FirstDate[r]
    else: String = String + " " + FirstDate[r]
    NewTimesDate.append(String)
#print(NewTimesDate)
#print("SecondDate:")
#print(SecondDate)

DatetimeList = list()
TimesList = list()
for i in range(NewTimesDate.__len__()):
    d = datetime.fromisoformat(NewTimesDate[i] + ".000")
    DatetimeList.append(d)
    SplitList = NewTimesDate[i].split()
    TimesList.append(SplitList[1])
    print("DateTimeFormat: ", d)
print("Figure Day")
fig, ax = plt.subplots() # Create a figure containing a single axes.
plt.ylabel("Scale of Points")
plt.xlabel("Scale of DateTime")
ax.plot(TimesList, MaxRangesList)  # Plot some data on the axes.
plt.show()
