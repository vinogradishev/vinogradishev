using System;
using System.Text;
using System.Collections.Generic;
using System.Threading.Channels;
using System.Security.Cryptography.X509Certificates;
using System.Linq.Expressions;
using StackWithStackItem;

namespace StackWithStackItem
{
    class TestException
    {
        static void Main() 
        {

            var s = new Stack("a", "b", "c");
            // size = 3, Top = 'c'
            Console.WriteLine($"size = {s.Size}, Top = '{s.Top}'");
            var deleted = s.Pop();
            // Извлек верхний элемент 'c' Size = 2
            Console.WriteLine($"Извлек верхний элемент '{deleted}' Size = {s.Size}");
            s.Add("d");
            // size = 3, Top = 'd'
            s.Pop();
            s.Pop();
            s.Pop();

            // size = 0, Top = null
            Console.WriteLine($"size = {s.Size}, Top = {(s.Top == null ? "null" : s.Top)}");
            s.Pop();
            s.Pop();
            s.Pop();
        }
    }   
}