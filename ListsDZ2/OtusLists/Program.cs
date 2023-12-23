﻿using System.Collections;
using System.Diagnostics;

namespace OtusLists
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var checkList = new List<int>(1000000);
            var checkArrList = new ArrayList(1000000);
            var checkLinkedList = new LinkedList<int>();

            PushElementsToLists(checkList, checkArrList, checkLinkedList);
            Console.WriteLine("-------------------------------------------------------------------------");
            FindElementsInLists(checkList, checkArrList, checkLinkedList);
            Console.WriteLine("-------------------------------------------------------------------------");
            DivideElements(checkList, checkArrList, checkLinkedList);
            Console.WriteLine();
            Console.WriteLine("На выполнение задания ушло примерно 8 часов.");
            Console.ReadKey();
        }
        static void PushElementsToLists(List<int> pushNumberList, ArrayList pushNumberArList, LinkedList<int> pushNumberLList) 
        {
            Stopwatch sw = new Stopwatch();
            sw.Start();
            for (int i = 1; i <= 1000000; i++)
            {
                pushNumberList.Add(i);
            }
            sw.Stop();
            TimeSpan timeCheckList = sw.Elapsed;
            string elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds,timeCheckList.Milliseconds);
            Console.WriteLine($"List заполнился за {elapsedTime}, количество элементов {pushNumberList.Count}");
            sw.Restart();
            for (int i = 1; i <= 1000000; i++)
            {
                pushNumberArList.Add(i);
            }
            sw.Stop();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine($"ArrayList заполнился за {elapsedTime}, количество элементов {pushNumberArList.Count}");
            sw.Restart();
            for (int i = 1; i <= 1000000; i++)
            {
                pushNumberLList.AddLast(i);
            }
            sw.Stop();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine($"LinkedList заполнился за {elapsedTime}, количество элементов {pushNumberLList.Count}");
        }
        static void FindElementsInLists(List<int> pushNumberList, ArrayList pushNumberArList, LinkedList<int> pushNumberLList)
        {
            Stopwatch sw = new Stopwatch();
            
            int element = 0;
            
            object elementList;

            sw.Start();
            element = pushNumberList[496753];
            sw.Stop();
            TimeSpan timeCheckList = sw.Elapsed;
            string elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine($"Элемент найден за {elapsedTime}, значение = {element}");
            
            sw.Restart();
            elementList = pushNumberArList[496753];
            sw.Stop();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine($"Элемент найден за {elapsedTime}, значение = {elementList}");
            
            List<int> result = new List<int>();
            sw.Restart();
            foreach (int i in pushNumberLList) 
            {
                if (i == 496753)
                {
                    result.Add(i);
                    break;
                }
                else
                {
                    continue;
                }
            }
            sw.Stop();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine($"Элемент найден за {elapsedTime}, значение = {result[0]}");
        }
        static void DivideElements(List<int> divNumberList, ArrayList divNumberArList, LinkedList<int> divNumberLList)
        {
            Stopwatch sw = new Stopwatch();

            List<int> result = new List<int> { };

            sw.Start();
            const string UNDERLINE = "\x1B[4m";
            const string RESET = "\x1B[0m";
            Console.Write(UNDERLINE + "Эелемнты List, которые делфтся на 777 без остатка:" + RESET + " ");
            foreach (int item in divNumberList)
            {
                if (item%777 == 0)
                {
                    Console.Write(item + " ");
                    result.Add(item);
                }
                else
                {
                    continue;
                }
            }
            sw.Stop();
            Console.WriteLine();
            TimeSpan timeCheckList = sw.Elapsed;
            string elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine();
            Console.WriteLine($"Элементы найдены за {elapsedTime}, количество элементов: {result.Count}");
            result.Clear();
            Console.WriteLine("-------------------------------------------------------------------------");
            sw.Restart();
            Console.Write(UNDERLINE + "Эелемнты ArrayList, которые делфтся на 777 без остатка:" + RESET + " ");
            foreach (int item in divNumberArList)
            {
                
                if (item % 777 == 0)
                {
                    Console.Write(item + " ");
                    result.Add(item);
                }
                else
                {
                    continue;
                }
            }
            sw.Stop();
            Console.WriteLine();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine();
            Console.WriteLine($"Элементы найдены за {elapsedTime}, количество элементов: {result.Count}");
            result.Clear();
            Console.WriteLine("-------------------------------------------------------------------------");
            Console.Write(UNDERLINE + "Эелемнты LinkedList, которые делфтся на 777 без остатка:" + RESET + " ");
            sw.Restart();
            foreach (int i in divNumberLList)
            {
                if (i%777 == 0)
                {
                    result.Add(i);
                }
                else
                {
                    continue;
                }
            }
            sw.Stop();
            foreach (int i in result) 
            {
                Console.Write(i + " ");
            }
            Console.WriteLine();
            timeCheckList = sw.Elapsed;
            elapsedTime = String.Format("{0:00}s.{1:0000}ms",
            timeCheckList.Seconds, timeCheckList.Milliseconds);
            Console.WriteLine();
            Console.WriteLine($"Элементы найдены за {elapsedTime}, количество элементов: {result.Count}");
        }
    }
}

