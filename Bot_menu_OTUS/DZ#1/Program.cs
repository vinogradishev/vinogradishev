namespace DZ_1
{
    internal class Program
    {
        static void Main(string[] args)
        {
            string? userName = string.Empty;
            string? inputCommand = string.Empty;
            string? inputCommandLowerCase = string.Empty;
            string appVersion = "v.1.0.0_19.11.23";
            string help = "/start - начало работы с ботом,\n/help - вызов справки,\n/info - версия бота,\n/exit - выход,\n/echo - вывод текста в консоль. Команда доступна после ввода имени пользователя";
            
            Console.WriteLine("Здравствуйте! Вас приветствует интерактивный бот. Доступные команды: /start, /help, /info, /exit.");
            Console.WriteLine("Для начала введите команду.");
            
            do
            {
                inputCommand = Console.ReadLine();
                inputCommandLowerCase = inputCommand.ToLower();
                switch (inputCommandLowerCase) 
                {
                    case "/start":
                        Console.WriteLine("Пожалуйста, введите ваше имя.");
                        userName = Console.ReadLine();
                        Console.WriteLine($"Привет, {userName}, что делаем дальше?");
                        break;
                    case "/help":
                        if (userName == string.Empty)
                        {
                            Console.WriteLine("Спарвка по работе с ботом:\n" + help);
                        }
                        else 
                        {
                            Console.WriteLine($"{userName}, вот спарвка по работе с ботом:\n" + help);
                        }
                        Console.WriteLine($"{userName}, что делаем дальше?");
                        break;
                    case "/info":
                        if (userName == string.Empty)
                        {
                            Console.WriteLine("Версия программы: " + appVersion);
                        }
                        else
                        {
                            Console.WriteLine($"{userName}, версия программы " + appVersion);
                        }
                        Console.WriteLine($"{userName}, что делаем дальше?");
                        break;
                    case "/exit":
                        if (userName == string.Empty)
                        {
                            Console.WriteLine("До свидания.");
                        }
                        else
                        {
                            Console.WriteLine($"{userName}, до свидания.");
                        }                        
                        break;
                    default:
                        if (inputCommandLowerCase.StartsWith("/echo"))
                        {
                            if (userName == string.Empty)
                            {
                                Console.WriteLine("Команда доступна после ввода имени.");
                            }
                            else
                            {
                                Console.WriteLine(inputCommand["/echo".Length..].Trim());
                                Console.WriteLine($"{userName}, что делаем дальше?");
                            }                            
                        }
                        else
                        {
                            if (userName == string.Empty)
                            {
                                Console.WriteLine("Вы ввели что-то непонятное. :0");
                            }
                            else
                            {
                                Console.WriteLine($"{userName}, вы ввели что-то непонятное. :0 ");
                            }
                        }
                        break;
                }
            } while (inputCommand != "/exit");
        }
    }
}