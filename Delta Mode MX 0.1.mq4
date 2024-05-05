//+------------------------------------------------------------------+
//|                                                Delta Mode MX 0.1 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- Inputs
extern double Lots       = 1.0;      // лот

extern int StopLoss1      = 300;      // лось
extern int TakeProfit1    = 150;      // язь

extern int StartHour     = 9;        // час начала торговли
extern int StartMin      = 0;        // минута начала торговли
extern int EndHour       = 20;       // час окончания торговли
extern int EndMin        = 0;        // минута окончания торговли

extern int Delta1        = 140;      // размер свечи от
extern int Delta2        = 250;      // размер свечи до
extern int CloseSig      = 1;        // закрытие по сигналу

extern int MinOpen       = 45;       // минуты для открытия
extern int Slip          = 30;       // реквот
extern int Magic         = 123;      // магик
const double QuantityElimLots = 6;  // количество лотов для усреднения
datetime t=0;
#define SELL 0
#define BUY 1
int MAGICNumber = Magic;
#include <Analytics/TrendFractals.mqh>
#include <Arrays/ArrayString.mqh>
#include <InfoOrders.mqh>
#include <JAson.mqh>
TrendFractals *MaxMinFractal;
//+------------------------------------------------------------------+
//| Expert initialization function.                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   /*for(int i = 0; i < 50; i++)
     {
      MasTickets[i] = -1;

     }*/
   MaxMinFractal = new TrendFractals();
   Comment("");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function.                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
//| Function for opening orders. Old version.                                                                |
//+------------------------------------------------------------------+
int PutOrder(int type,double price)
  {
   int r=0;
   color clr=Green;
   double sl=0,tp=0;

   if(type==1 || type==3 || type==5)
     {
      clr=Red;
      if(StopLoss1>0)
         sl=NormalizeDouble(price+StopLoss1*_Point,_Digits);
      if(TakeProfit1>0)
         tp=NormalizeDouble(price-TakeProfit1*_Point,_Digits);
     }

   if(type==0 || type==2 || type==4)
     {
      clr=Blue;
      if(StopLoss1>0)
         sl=NormalizeDouble(price-StopLoss1*_Point,_Digits);
      if(TakeProfit1>0)
         tp=NormalizeDouble(price+TakeProfit1*_Point,_Digits);
     }

   r=OrderSend(NULL,type,Lots,NormalizeDouble(price,_Digits),Slip,0,tp,"",Magic,0,clr);
   return r;
  }


//+------------------------------------------------------------------+
//|Convert Minutes in bars for M15 timeframe.                                                                 |
//+------------------------------------------------------------------+
int CalculateBars(int RangeInMinuts)
  {
   return ((int)NormalizeDouble(RangeInMinuts/15, 0));
  }

struct CandleSize
  {
   double            OpenPrice;
   double            ClosePrice;
  };
CandleSize OpenOrderCandle = {0,0};
//+------------------------------------------------------------------+
//| Function for control Close time in period MinOpen.                                                                 |
//+------------------------------------------------------------------+
bool TimeClose()
  {
   if(OpenOrderCandle.ClosePrice != 0 && OpenOrderCandle.OpenPrice != 0)
      for(int i = 1; i <= CalculateBars(MinOpen); i++)
        {
         if(OpenOrderCandle.ClosePrice == Close[i] && OpenOrderCandle.OpenPrice == Open[i])
           {
            return true;
           }
        }

   return false;
  }

//+------------------------------------------------------------------+
//|Function for control time session.                                                                  |
//+------------------------------------------------------------------+
bool TimeSession(int aStartHour,int aStartMinute,int aStopHour,int aStopMinute,datetime aTimeCur)
  {
//--- время начала сессии
   int StartTime=3600*aStartHour+60*aStartMinute;
//--- время окончания сессии
   int StopTime=3600*aStopHour+60*aStopMinute;
//--- текущее время в секундах от начала дня
   aTimeCur=aTimeCur%86400;
   if(StopTime<StartTime)
     {
      //--- переход через полночь
      if(aTimeCur>=StartTime || aTimeCur<StopTime)
        {
         return(true);
        }
     }
   else
     {
      //--- внутри одного дня
      if(aTimeCur>=StartTime && aTimeCur<StopTime)
        {
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//|Function to control whether the order is closed or not.                                                             |
//+------------------------------------------------------------------+
bool IsOrderClose(int ticket)
  {
   for(int i = OrdersTotal() -1;  i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==true)
        {
         if(OrderTicket() == ticket)
            return false;
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//|The function returns the last ticket in the list of orders history.                                                                  |
//+------------------------------------------------------------------+
int LastOrderOP()
  {
//Print("StartLastOrderOP");
   if(OrderSelect(OrdersHistoryTotal()-1, SELECT_BY_POS, MODE_HISTORY)==true)
     {
      return OrderType();
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|Function for calculate take profit and stop loss                                                                  |
//+------------------------------------------------------------------+
double CalculatePnL(double FirstPrice, double SecondPrice, double Lot, bool OP)
  {
   if(OP == BUY)
     {
      return NormalizeDouble((SecondPrice-FirstPrice)*Lot*100, Digits);
     }
   if(OP == SELL)
     {
      return NormalizeDouble((FirstPrice-SecondPrice)*Lot*100, Digits);
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Finding a range in points between two prices.                                                                 |
//+------------------------------------------------------------------+
int PointsToRange(double Price1, double Price2, double PPoint)
  {
   if(Price1>Price2)
      return((int)NormalizeDouble((Price1-Price2)/PPoint, 0));
   if(Price1<Price2)
      return ((int)NormalizeDouble((Price2-Price1)/PPoint, 0));
   return 0;
  }

//+------------------------------------------------------------------+
//| Function for finding the elimination price                                                                 |
//+------------------------------------------------------------------+
double FindEliminationPrice()
  {
   int QuantityTickets = 0;
   for(int i = 0; i < 50; i++)
     {
      if(IsOrderClose(MasTickets[i]) != true)
        {
         QuantityTickets++;
        }
      else
         break;
     }
   if(QuantityTickets != 1)
      for(int i = QuantityTickets-1; i != -1; i--)
        {
         if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
           {
            if(OrderTakeProfit() != 0)
               return OrderTakeProfit();
           }
        }
   return 0;
  }

//+------------------------------------------------------------------+
//| Function for opening an order for averaging.                                                                 |
//+------------------------------------------------------------------+
int  MasTickets[50];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpenEliminationOrder(int LastTicket, int FirstTicket)
  {
//Print("Starting OpenEliminationOrder()...");
   double QuantityLots = 0;
   for(int i = 0; i < 50; i++)
     {
      if(MasTickets[i] != -1)
        {
         if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
           {
            QuantityLots +=OrderLots();
           }
         else
            break;
        }
     }
   if(QuantityLots > QuantityElimLots)
     {
      return -1;
     }
//Print("QuantityLots: ", QuantityLots);
//Print("LastTicket: ", LastTicket);
//Print("FirstTicket: ", FirstTicket);
   double minstoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   if(LastTicket == FirstTicket)
     {
      MasTickets[0] = FirstTicket;
      if(OrderSelect(FirstTicket, SELECT_BY_TICKET) == true)
        {
         if(OrderType() == OP_BUY)
           {
            double FirstTicketOpenPrice = OrderOpenPrice();
            double LastTicketOpenPrice = 0;
            LastTicket = BuyOrder(0, 0, (OrderLots()*2));
            if(LastTicket == -1)
              {
               MasTickets[0] = -1;
               return -1;
              }
            else
               if(OrderSelect(LastTicket, SELECT_BY_TICKET) == true)
                 {
                  LastTicketOpenPrice = OrderOpenPrice();
                  int Range = PointsToRange(FirstTicketOpenPrice, LastTicketOpenPrice, Point);
                  //double PNLOpenOrders = CalculatePnL(FirstTicketOpenPrice, LastTicketOpenPrice, Lots, BUY);
                  if(OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble((Range/2+3)*Point+minstoplevel+OrderOpenPrice()+(Ask-Bid), Digits), 0, clrRed) == true)
                    {
                     MasTickets[1] = LastTicket;
                     if(OrderSelect(FirstTicket, SELECT_BY_TICKET) == true)
                       {
                        if(OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble((OrderOpenPrice()-(Range/2)*Point+minstoplevel)+(Ask-Bid), Digits), 0, clrRed) == true)
                          {
                           TimeFirstElimBar = Time[0];
                           ElimDirectionTrend = DOWN;
                           return LastTicket;
                          }
                        else
                           Print(" Error: First order is not modified!\nError code: ", GetLastError());
                       }

                    }
                  else
                     Print(" Error: Last averaged order is not modified!\nError code: ", GetLastError());
                 }
           }
         else
            if(OrderType() == OP_SELL)
              {
               double FirstTicketOpenPrice = OrderOpenPrice();
               double LastTicketOpenPrice = 0;
               LastTicket = SellOrder(0, 0, (OrderLots()*2));
               if(LastTicket == -1)
                 {
                  MasTickets[0] = -1;
                  return -1;
                 }
               else
                  if(OrderSelect(LastTicket, SELECT_BY_TICKET) == true)
                    {
                     LastTicketOpenPrice = OrderOpenPrice();
                     int Range = PointsToRange(FirstTicketOpenPrice, LastTicketOpenPrice, Point);

                     if(OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()-(Range/2+3)*Point+minstoplevel-(Ask-Bid), Digits), 0, clrRed) == true)
                       {
                        MasTickets[1] = LastTicket;
                        if(OrderSelect(FirstTicket, SELECT_BY_TICKET) == true)
                          {

                           if(OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble((OrderOpenPrice()+(Range/2)*Point+minstoplevel)-(Ask-Bid), Digits), 0, clrRed) == true)
                             {
                              TimeFirstElimBar = Time[0];
                              ElimDirectionTrend = UP;
                              return LastTicket;
                             }
                           else
                              Print(" Error: First order is not modified!\nError code: ", GetLastError());

                          }
                        else
                           Print(" Error: Last averaged order is not modified!\nError code: ", GetLastError());
                       }
                    }
              }
        }
     }
   else
     {
      if(QuantityLots < QuantityElimLots)
        {
         int NewTicket = -1;
         int QuantityOrders = 0;
         for(int i = 0; i < 50; i++)
           {
            if(IsOrderClose(MasTickets[i]) != true)
               QuantityOrders++;
            else
               if(QuantityOrders != 0)
                  break;
           }
         //Print("QuantityOrders: ", QuantityOrders);
         if(QuantityOrders >= 2)
           {
            if(OrderSelect(MasTickets[0], SELECT_BY_TICKET) == true)
              {
               double Qlots = Lots;
               for(int r = 0; r < QuantityOrders; r++)
                 {
                  Qlots = Qlots*2;
                 }
               if(OrderType() == OP_BUY)
                  NewTicket = BuyOrder(0,0, Qlots);
               else
                  if(OrderType() == OP_SELL)
                     NewTicket = SellOrder(0,0,Qlots);
              }
            double LastElimPrice = 0;
            double NewElimPrice = 0;
            double LastOrdersLot = 0;
            double LastOrderOpenPrice = 0;
            for(int i = QuantityOrders-1; i != -1; i--)
              {

               if(QuantityOrders-1 == i)
                 {
                  if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
                    {


                     LastElimPrice = FindEliminationPrice();
                     LastOrderOpenPrice = OrderOpenPrice();
                     for(int r = 0; r < QuantityOrders; r++)
                       {
                        if(OrderSelect(MasTickets[r], SELECT_BY_TICKET) == true)
                          {
                           LastOrdersLot +=OrderLots();
                          }
                       }
                     if(OrderSelect(NewTicket, SELECT_BY_TICKET) == true)
                       {
                        MasTickets[i+1] = NewTicket;
                        int LastRange = PointsToRange(LastElimPrice, OrderOpenPrice(), Point);
                        if(OrderType() == OP_BUY)
                          {
                           NewElimPrice = minstoplevel+OrderOpenPrice()+LastRange*OrderLots()/(LastOrdersLot+OrderLots()*2)*Point+(Ask-Bid);
                          }
                        else
                           if(OrderType() == OP_SELL)
                             {
                              NewElimPrice = minstoplevel+OrderOpenPrice()-LastRange*OrderLots()/(LastOrdersLot+OrderLots()/2)*Point-(Ask-Bid);
                              //NewElimPrice = minstoplevel+OrderOpenPrice()-((OrderOpenPrice()-LastOrderOpenPrice)/Point*OrderLots()/(LastOrdersLot+OrderLots()))*Point-(Ask-Bid);
                             }
                        if(OrderModify(NewTicket, OrderOpenPrice(), 0, NormalizeDouble(NewElimPrice+3*Point, Digits), 0, clrRed) != true)
                           Print("Error: New Order is not modified!");

                       }
                     else
                       {
                        Print("Error: New Ticket is not opened!");
                        return -1;
                       }
                    }
                  if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
                    {

                     if(OrderModify(MasTickets[i], OrderOpenPrice(), 0, NormalizeDouble(NewElimPrice, Digits), 0, clrRed) != true)
                        Print("Error: Order:", MasTickets[i], " is not modified!");
                    }
                 }
               else
                 {
                  if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
                    {

                     if(OrderModify(MasTickets[i], OrderOpenPrice(), 0, NormalizeDouble(NewElimPrice, Digits), 0, clrRed) != true)
                        Print("Error: Order:", MasTickets[i], " is not modified!");
                     if(i == 0)
                        return NewTicket;
                    }
                 }
              }
           }
        }
     }
//Print("EndFunc()");
   return 0;
  }

//+------------------------------------------------------------------+
//|Open Buy Order.                                                                  |
//+------------------------------------------------------------------+
int BuyOrder(int TakeProfit, int StopLoss, double VVolume)
  {

   double minstoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   double NormalST;
   double NormalTP;
   if(StopLoss == 0)
     {
      NormalST = 0;
     }
   else
     {
      NormalST = NormalizeDouble(Bid+minstoplevel-StopLoss*Point, Digits);
     }
   if(TakeProfit == 0)
     {
      NormalTP = 0;
     }
   else
     {
      NormalTP = NormalizeDouble(Bid+minstoplevel+TakeProfit*Point, Digits);
     }
   int ticket = OrderSend(Symbol(), OP_BUY, NormalizeDouble(VVolume, 2), Ask, 3, NormalST, NormalTP, "Delta Mode MX 0.1", MAGICNumber, 0, clrGreen);
   return ticket;
  }

//+------------------------------------------------------------------+
//|Open Sell Order.                                                                  |
//+------------------------------------------------------------------+
int SellOrder(int TakeProfit, int StopLoss, double VVolume)
  {

   double minstoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   double NormalST;
   double NormalTP;
   if(StopLoss == 0)
     {
      NormalST = 0;
     }
   else
     {
      NormalST = NormalizeDouble(Ask+minstoplevel+StopLoss*Point, Digits);
     }
   if(TakeProfit == 0)
     {
      NormalTP = 0;
     }
   else
     {
      NormalTP = NormalizeDouble(Ask-minstoplevel-TakeProfit*Point, Digits);
     }
   int ticket = OrderSend(Symbol(), OP_SELL, NormalizeDouble(VVolume, 2), Bid, 3, NormalST, NormalTP, "Delta Mode MX 0.1", MAGICNumber, 0, clrRed);
   return ticket;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Removes unnecessary tickets from the Mastickets array.                                                                  |
//+------------------------------------------------------------------+
void ControlMasTickets()
  {
   for(int i = 0; i < 50; i++)
     {
      if(IsOrderClose(MasTickets[i]) == true)
        {
         MasTickets[i] = -1;
        }
     }
  }

//+------------------------------------------------------------------+
//| Correcting the sequence of tickets in the Mastickets array.                                                                 |
//+------------------------------------------------------------------+
void RepairMasTickets()
  {
   int FirstIndex = -1;
   int SecondIndex = -1;
   int Index = 0;
   ControlMasTickets();
   for(int i = 0; i < 50; i++)
     {
      if(IsOrderClose(MasTickets[i]) != true)
        {
         //Print("++");
         if(i == 0)
           {
            Index++;
           }
         if(FirstIndex == -1 && SecondIndex == -1 && Index == 0)
            FirstIndex = i;
         if(FirstIndex != -1 && SecondIndex == -1 && Index == 0)
           {
            //Print("__");
            if((i != 49 && MasTickets[i+1] == -1) || i == 49)
               SecondIndex = i;

           }

         if(FirstIndex != -1 && SecondIndex != -1)
           {
            //Print("FirstIndex = ", FirstIndex);
            //Print("SecondIndex = ", SecondIndex);
            if(FirstIndex == SecondIndex)
              {
               for(int k = 0; k < 50; k++)
                 {
                  //Print("777");
                  if(IsOrderClose(MasTickets[k]) != true && (MasTickets[k+1] == -1 && i != 49) || i == 49)
                    {
                     MasTickets[k+1] = MasTickets[FirstIndex];
                     MasTickets[FirstIndex] = -1;
                     break;
                    }
                  else
                     if(MasTickets[0] == -1)
                       {
                        MasTickets[0] = MasTickets[FirstIndex];
                        MasTickets[FirstIndex] = -1;
                        break;
                       }
                 }

              }
            else
               if(FirstIndex != SecondIndex)
                 {
                  for(int k = 0; k < 50; k++)
                    {
                     if(IsOrderClose(MasTickets[k]) == true && FirstIndex > k)
                       {
                        for(int Rep = k; Rep < k+(SecondIndex-FirstIndex); Rep++)
                          {
                           MasTickets[Rep] = MasTickets[Rep+FirstIndex];
                           MasTickets[Rep+FirstIndex] = -1;
                          }

                       }
                    }
                 }

           }
        }
      else
         if(Index != 0 && IsOrderClose(MasTickets[i]) == true)
           {
            Index = 0;
           }
     }

   return;
  }

//+------------------------------------------------------------------+
//| Expert tick function.                                             |
//+------------------------------------------------------------------+
int Ticket = -1;
bool IsFirstOrder = true;
datetime LastClosedBar = 0;
CArrayString *JASONData = new CArrayString();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ShowTicketTakeProfit(int TradeTicket)
  {
   if(OrderSelect(TradeTicket, SELECT_BY_TICKET) == true)
     {
      return OrderTakeProfit();
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ShowTicketOpenPrice(int TradeTicket)
  {
   if(OrderSelect(TradeTicket, SELECT_BY_TICKET) == true)
     {
      return OrderOpenPrice();
     }
   return 0;
  }
int ElimDirectionTrend = 0;
double ElimTakeProfit;
double ElimOpenPrice;
datetime TimeFirstElimBar = 0;
datetime TimeDate = NULL;
int CurrentDay = NULL;
int CurrentYear = NULL;
int ElimIndex = 0;
void OnTick()
  {
   double minstoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   if(Period() == PERIOD_M15)
     {
      if(TimeDate == NULL)
        {
         CurrentDay = TimeDayOfYear(TimeCurrent());
         CurrentYear = TimeYear(TimeCurrent());
         TimeDate = TimeCurrent();
        }
      //Print("OpenOrderCandle.OpenPrice: ", OpenOrderCandle.OpenPrice);
      //Print("OpenOrderCandle.ClosePrice: ", OpenOrderCandle.ClosePrice);
      if(IsFirstOrder == true)
        {
         for(int i = 0; i < 50; i++)
           {
            MasTickets[i] = -1;
           }
         for(int i = 0; i < OrdersTotal(); i++)
           {
            if(OrderSelect(i, SELECT_BY_POS) == true)
              {
               if(MAGICNumber == OrderMagicNumber())
                  MasTickets[i] = OrderTicket();
              }
           }
        }

      RepairMasTickets();
      if(MasTickets[0] == -1 && JASONData.Total() != 0)
        {
         int IndexBars = 0;
         double BuffFractals[];
         Print("TimeFirstElimBar: ", TimeFirstElimBar);
         for(int i = 0; TimeFirstElimBar <= Time[i]; i++)
           {
            IndexBars++;
           }
         ArrayResize(BuffFractals, IndexBars, 0);
         for(int i = 0; i < IndexBars; i++)
           {
            if(ElimDirectionTrend == UP)
               BuffFractals[i] = iFractals(_Symbol,PERIOD_CURRENT, MODE_UPPER, i);
            else
               if(ElimDirectionTrend == DOWN)
                  BuffFractals[i] = iFractals(_Symbol,PERIOD_CURRENT, MODE_LOWER, i);
           }

         MaxMinFractal.Set(BuffFractals, ElimDirectionTrend);
         CJAVal JSFractal, JSIndex;
         
         if(ElimDirectionTrend == UP)
            JSFractal["MaxFractal"] = IntegerToString(MaxMinFractal.GetMaxFractal(), 0, ' ');
         else
            if(ElimDirectionTrend == DOWN)
               JSFractal["MinFractal"] = IntegerToString(MaxMinFractal.GetMaxFractal(), 0, ' ');
         JSIndex["Index_"+IntegerToString(ElimIndex, 0, ' ')].Add(JSFractal);
         string FileName = "AnalyticsLog" + TimeToString(TimeDate, TIME_DATE) + ".txt";
         
         
         Print("JASONData.Total: ", JASONData.Total());
         for(int i = 0; i < JASONData.Total(); i++)
         {
            JSIndex["Index_"+IntegerToString(ElimIndex, 0, ' ')].Add(JASONData[i]);
         }
         if(WriteFile(FileName, JSIndex.Serialize()))
            Print("WriteFile Succesfull!");
         ElimIndex++;
         JASONData.DeleteRange(0, JASONData.Total()-1);
         TimeFirstElimBar = 0;
         ElimDirectionTrend = 0;
         if(CurrentDay < TimeDayOfYear(TimeCurrent()) && CurrentYear == TimeYear(TimeCurrent()))
           {
            CurrentDay = TimeDayOfYear(TimeCurrent());
            CurrentYear = TimeYear(TimeCurrent());
            TimeDate = TimeCurrent();
            ElimIndex = 0;
           }
         else
            if(CurrentDay > TimeDayOfYear(TimeCurrent()) && CurrentYear != TimeYear(TimeCurrent()))
              {
               CurrentDay = TimeDayOfYear(TimeCurrent());
               CurrentYear = TimeYear(TimeCurrent());
               TimeDate = TimeCurrent();
               ElimIndex = 0;
              }
        }
      double delta=Close[1]-Open[1];
      bool buy = delta>=Delta1*_Point && delta<Delta2*_Point;
      bool sell = delta<=-Delta1*_Point && delta>-Delta2*_Point;
      if(IsOrderClose(Ticket) == true)
        {
         Ticket = -1;
         for(int i = 0; i < 50; i++)
           {
            if(IsOrderClose(MasTickets[i]) != true)
               Ticket = MasTickets[i];
            else
               break;
           }
         OpenOrderCandle.OpenPrice = 0;
         OpenOrderCandle.ClosePrice = 0;
        }
      if(Ticket != -1)
        {
         int Index = 0;
         for(int i = 0; i < 50; i++)
           {
            if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
               Index++;
            else
               break;
           }
         if(Index != 0)
            for(int i = 0; i < Index; i++)
              {
               if(OrderSelect(MasTickets[i], SELECT_BY_TICKET) == true)
                  if(OrderTakeProfit() == 0 && OrderStopLoss() == 0)
                     if(OrderType() == OP_BUY && OrderOpenPrice() < Close[0])
                       {
                        if(OrderClose(OrderTicket(), OrderLots(), Bid+minstoplevel, 0, clrBlueViolet) != true)
                           Print("Error: Order ", OrderTicket(), " : is not closed!");
                       }
                     else
                        if(OrderType() == OP_SELL && OrderOpenPrice() > Close[0])
                          {
                           if(OrderClose(OrderTicket(), OrderLots(), Ask+minstoplevel, 0, clrBlueViolet) != true)
                              Print("Error: Order ", OrderTicket(), " : is not closed!");
                          }
              }
        }
      /*
      Print("Indicator Buy: ", buy);
      Print("Indicator Sell:", sell);
      Print("TimeClose(): ", TimeClose());
      Print("LastOrderOP(): ",LastOrderOP());
      Print("OpenOrderCandle.ClosePrice: ", OpenOrderCandle.ClosePrice);
      Print("OpenOrderCandle.OpenPrice: ", OpenOrderCandle.OpenPrice);
      Print("Indicator t: ", t);
      */
      if(t!=Time[0] && ((TimeClose() == false && LastOrderOP() == OP_BUY && buy == true) || (TimeClose() == false && LastOrderOP() == OP_SELL && sell == true)
                        || (TimeClose() == false || IsFirstOrder == true) || ((LastOrderOP() == OP_BUY && sell == true) || (LastOrderOP() == OP_SELL && buy == true)
                              && Ticket == -1)) && TimeSession(StartHour,StartMin,EndHour,EndMin,TimeCurrent()))
        {
         if(buy && Ticket == -1)
           {
            Ticket = PutOrder(0,Ask+minstoplevel);
            if(Ticket != -1)
              {
               OpenOrderCandle.OpenPrice = Open[1];
               OpenOrderCandle.ClosePrice = Close[1];
               IsFirstOrder = false;
              }
           }
         if(sell && Ticket == -1)
           {
            Ticket = PutOrder(1,Bid+minstoplevel);
            if(Ticket != -1)
              {
               OpenOrderCandle.OpenPrice = Open[1];
               OpenOrderCandle.ClosePrice = Close[1];
               IsFirstOrder = false;
              }
           }

         t=Time[0];
        }
      else
         if(IsOrderClose(Ticket)==true)
           {
            OpenOrderCandle.OpenPrice = 0;
            OpenOrderCandle.ClosePrice = 0;
            Ticket = -1;
           }
      //Comment("\n Time Close: ", TimeClose());

      if(OrderSelect(Ticket, SELECT_BY_TICKET) == true && LastClosedBar != Time[1])
        {
         int ElimTicket;
         if(OrderType() == OP_BUY && OrderOpenPrice()+(Ask-Bid) > Close[1] && (OpenOrderCandle.OpenPrice != Open[1] && OpenOrderCandle.ClosePrice != Close[1]))
           {
            ElimDirectionTrend = DOWN;
            if(MasTickets[0] == -1)
              {
               /*if(JASONData.Total() == 0)
               {
                  string JSTicket = WriteOpenOrderOnJason(Ticket);
                  JASONData.Add(JSTicket);
                  ElimTakeProfit = ShowTicketTakeProfit(Ticket);
                  ElimOpenPrice = ShowTicketOpenPrice(Ticket);
               }*/
               ElimTicket = OpenEliminationOrder(Ticket, Ticket);
               TimeFirstElimBar = Time[0];
               string JSTicket = WriteOpenOrderOnJason(MasTickets[0]);
               JASONData.Add(JSTicket);
               ElimTakeProfit = ShowTicketTakeProfit(MasTickets[0]);
               ElimOpenPrice = ShowTicketOpenPrice(MasTickets[0]);
               Ticket = ElimTicket;
               if(IsOrderClose(Ticket) != true)
                 {
                  string JSTicket = WriteOpenOrderOnJason(Ticket);
                  JASONData.Add(JSTicket);
                  ElimTakeProfit = ShowTicketTakeProfit(Ticket);
                  ElimOpenPrice = ShowTicketOpenPrice(Ticket);
                 }
               if(Ticket != -1)
                 {
                  LastClosedBar = Time[1];
                 }
               else
                 {
                  //Print("OpenEliminationOrder error: This Order is not opened!");
                 }
              }
            else
               if(MasTickets[0] != -1)
                 {
                  for(int i = 1; i < 50; i++)
                    {
                     if(MasTickets[i] == -1)
                       {
                        ElimTicket = OpenEliminationOrder(MasTickets[i-1], MasTickets[0]);
                        Ticket = ElimTicket;
                        if(IsOrderClose(Ticket) != true)
                          {
                           string JSTicket = WriteOpenOrderOnJason(Ticket);
                           JASONData.Add(JSTicket);
                           ElimTakeProfit = ShowTicketTakeProfit(Ticket);
                           ElimOpenPrice = ShowTicketOpenPrice(Ticket);
                          }
                        if(Ticket != -1)
                          {
                           LastClosedBar = Time[1];
                          }
                        else
                          {
                           //Print("OpenEliminationOrder error: This Order is not opened!");
                          }
                        break;
                       }
                    }
                 }
           }
         else
            if(OrderType() == OP_SELL && OrderOpenPrice()+(Ask-Bid) < Close[1] && (OpenOrderCandle.OpenPrice != Open[1] && OpenOrderCandle.ClosePrice != Close[1]))
              {
               ElimDirectionTrend = UP;
               if(MasTickets[0] == -1)
                 {
                  ElimTicket = OpenEliminationOrder(Ticket, Ticket);
                  Ticket = ElimTicket;
                  if(IsOrderClose(Ticket) != true)
                    {
                     string JSTicket = WriteOpenOrderOnJason(Ticket);
                     JASONData.Add(JSTicket);
                     ElimTakeProfit = ShowTicketTakeProfit(Ticket);
                     ElimOpenPrice = ShowTicketOpenPrice(Ticket);
                    }
                  if(Ticket != -1)
                    {
                     LastClosedBar = Time[1];
                    }
                  else
                    {
                     //Print("OpenEliminationOrder error: This Order is not opened!");
                    }
                 }
               else
                  if(MasTickets[0] != -1)
                    {
                     for(int i = 1; i < 50; i++)
                       {
                        if(MasTickets[i] == -1)
                          {
                           ElimTicket = OpenEliminationOrder(MasTickets[i-1], MasTickets[0]);
                           Ticket = ElimTicket;
                           if(IsOrderClose(Ticket) != true)
                             {
                              string JSTicket = WriteOpenOrderOnJason(Ticket);
                              JASONData.Add(JSTicket);
                              ElimTakeProfit = ShowTicketTakeProfit(Ticket);
                              ElimOpenPrice = ShowTicketOpenPrice(Ticket);
                             }
                           if(Ticket != -1)
                             {
                              LastClosedBar = Time[1];
                             }
                           else
                             {
                              //Print("OpenEliminationOrder error: This Order is not opened!");
                             }
                           break;
                          }
                       }
                    }
              }
        }

     }
   else
      Comment("It's not the M15 timeframe! Please change the timeframe.");


  }
//+------------------------------------------------------------------+
string WriteOpenOrderOnJason(int Ticket)
  {
   CJAVal InfoPositionJS;
   if(OrderSelect(Ticket, SELECT_BY_TICKET) == true)
     {
      InfoPositionJS["ID"] = OrderTicket();
      InfoPositionJS["OrderOpenPrice"] = OrderOpenPrice();
      InfoPositionJS["OrderLots"] = NormalizeDouble(OrderLots(), 2);
      InfoPositionJS["TakeProfit"] = NormalizeDouble(OrderTakeProfit(), 3);
      InfoPositionJS["StopLoss"] = NormalizeDouble(OrderStopLoss(), 3);
      if(OrderType() == OP_BUY)
         InfoPositionJS["OrderType"] = "OP_BUY";
      else
         if(OrderType() == OP_SELL)
            InfoPositionJS["OrderType"] = "OP_SELL";
      InfoPositionJS["OrderOpenTime"] = TimeToStr(OrderOpenTime(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
     }


   return InfoPositionJS.Serialize();



   return NULL;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool WriteFile(string FileName, string Data)
  {

   int FileHandle;
   if(FileIsExist(FileName, 0))
     {
      FileHandle = FileOpen(FileName, FILE_WRITE | FILE_READ| FILE_TXT);
      FileSeek(FileHandle, 0, SEEK_END);
     }
   else
     {
      FileHandle = FileOpen(FileName, FILE_WRITE | FILE_TXT);
     }
   if(FileWrite(FileHandle, Data) != 0)
     {
      FileWrite(FileHandle, "");
      FileClose(FileHandle);
      return true;
     }
   else
     {
      Print("FileError: ", GetLastError());
      FileClose(FileHandle);
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
