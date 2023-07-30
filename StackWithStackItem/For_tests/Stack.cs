using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace StackWithStackItem
{
    public class Stack
    {
        StackItem? _tailStackItem;
        //Счётчик элементов стэка
        int _countStack;
        
        public string? Top 
        {
            get 
            {
                if (_tailStackItem == null)
                {
                    return null;
                }
                else 
                {
                    return _tailStackItem.topStackItemValue; 
                }

            }
        }

        //Свойство "размер стэка"
        public int Size 
        {
            get 
            {
                return _countStack;
            } 
            
        }
        class StackItem 
        {
            //Значение текущего элемента
            string? _StackItemValue;
            //Ссылка на предыдущий элемент стека
            StackItem? _prevStackItem;
            
            //Свйоство элемента стэка для возврата и присваивания значения элемента стэка
            public string? topStackItemValue 
            {
                get { return _StackItemValue; }
            }

            //Свойство элемента стэка для возврата и присваивания ссылки на предыдущий элемент
            public StackItem? prevStackItem 
            {
                get 
                {
                    return _prevStackItem;
                }
                set
                {
                    _prevStackItem = value;
                }
            }
            public StackItem(string value) 
            {
                _StackItemValue = value;
            }
        }
        public Stack(params string[] inputList) 
        {
            _tailStackItem = new StackItem(inputList[0]);
            _countStack = 1;
            for (int i = 1; i < inputList.Length; i++) 
            {
                _countStack++;
                StackItem newItem = new StackItem(inputList[i]);
                newItem.prevStackItem = _tailStackItem;
                _tailStackItem = newItem;
            }
        }
        public void Add(string inputString) 
        {
            _countStack++;
            StackItem newItem = new StackItem(inputString);
            newItem.prevStackItem = _tailStackItem;
            _tailStackItem = newItem;
        }
        public string? Pop() 
        {
            string? result;
            try
            {
                if (_countStack == 0)
                {
                    throw new Exception("Стек пустой");
                }
                result = _tailStackItem.topStackItemValue;
                _tailStackItem = _tailStackItem.prevStackItem;
                _countStack--;
                return result;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return null;
            }
        }
    }
}
