namespace StackOtus
{
    public class Stack
    {
        List<string> stackList;

        public List<string> stackProp
        {
            get
            {
                return stackList;
            }
        }

        public int Size
        {
            get
            {
                return stackList.Count;
            }
        }

        public string? Top
        {
            get
            {
                if (stackList.Count == 0)
                {
                    return null;
                }
                else
                {
                    return stackList[stackList.Count - 1];
                }
            }
        }

        public Stack(params string[] stackList)
        {
            this.stackList = new List<string>(stackList);
        }
        public void Add(string inputString)
        {
            this.stackList.Add(inputString);
        }
        public string Pop()
        {
            try
            {
                if (stackList.Count == 0)
                {
                    throw new Exception("Стэк пустой.");
                }
                else
                {
                    string a = stackList[stackList.Count - 1];
                    stackList.RemoveAt(stackList.Count - 1);
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
