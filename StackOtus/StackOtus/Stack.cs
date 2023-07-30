namespace StackOtus
{
    public class Stack
    {
        List<string> _stackList;

        public int Size
        {
            get
            {
                return _stackList.Count;
            }
        }

        public string? Top => _stackList.Count == 0 ? null : _stackList[^1];

        public Stack(params string[] stackList)
        {
            _stackList = new List<string>(stackList);
        }
        public void Add(string inputString)
        {
            _stackList.Add(inputString);
        }
        public string Pop()
        {
            try
            {
                if (_stackList.Count == 0)
                {
                    throw new Exception("Стэк пустой.");
                }
                else
                {
                    string a = _stackList[_stackList.Count - 1];
                    _stackList.RemoveAt(_stackList.Count - 1);
                    return a;
                }
            }
            catch (Exception e) 
            { 
                Console.WriteLine(e.Message);
                return string.Empty;
            }
        }
        public static Stack Concat(params Stack[] stacks)
        {
            int arrayLength = stacks.Length;
            Stack outStack = new Stack();
            for (int i = 0; i < arrayLength; i++)
            {
                int stackLength = stacks[i].Size;
                for (int j = 0; j < stackLength; j++)
                {
                    outStack.Add(stacks[i].Pop());
                }
            }
            return outStack;
        }
    }
}
