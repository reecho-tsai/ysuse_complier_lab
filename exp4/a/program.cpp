#include <cstdio>
#include <cstring>
#include <iostream>

using namespace std;

char symbol;
int front, len, t;
char ex[100];
char str[100];

double calc()
{
    double d;
    double stack[100], xx = 0;
    front = -1;

    for (int t = 0; t < len;)
    {
        symbol = ex[t];

        switch (symbol)
        {
        case '+':
            stack[front - 1] = stack[front - 1] + stack[front];
            front--;
            t++;
            break;

        case '-':
            stack[front - 1] = stack[front - 1] - stack[front];
            front--;
            t++;
            break;

        case '*':
            stack[front - 1] = stack[front - 1] * stack[front];
            front--;
            t++;
            break;

        case '/':
            if (stack[front] != 0)
                stack[front - 1] = stack[front - 1] / stack[front];
            else
            {
                printf("\n\t Divided by zero!!\n");
                break;
            }
            front--;
            t++;
            break;

        case '^':
            xx = stack[front - 1];
            for (int i = 0; i < stack[front] - 1; i++)
            {
                xx = xx * stack[front - 1];
            }
            stack[front - 1] = xx;
            front--;
            t++;
            break;

        default:
            d = 0;
            int flag = false;
            while (symbol == '@' || (symbol >= '0' && symbol <= '9'))
            {
                if (symbol == '@')
                {
                    flag = true;
                    t++;
                    symbol = ex[t];
                    continue;
                }
                d = 10 * d + symbol - '0';
                t++;
                symbol = ex[t];
            }

            if (symbol == '.')
            {
                double temp = 0;
                t++;
                symbol = ex[t];
                int k = 1;
                while ((symbol >= '0' && symbol <= '9') || symbol == '@')
                {
                    if (symbol == '@')
                    {
                        flag = true;
                        t++;
                        symbol = ex[t];
                        continue;
                    }
                    double temp1 = 1;
                    for (int s = 0; s < k; s++)
                    {
                        temp1 *= 0.1;
                    }
                    temp = temp + temp1 * (symbol - '0');
                    t++;
                    symbol = ex[t];
                }
                d += temp;
            }

            if (symbol == '&')
            {
                t++;
                symbol = ex[t];
            } 

            front++;

            if (flag == true)
            {
                d = -d;
            }
            stack[front] = d;
        }
    }
    return stack[0];
}
int main()
{
    char stack[100];
    memset(stack, 0, sizeof(stack));
    len = 0; 

    while (true)
    {
        scanf("%c", &symbol);
        if (symbol == '#')
        {
            break;
        }
        str[len++] = symbol;
    }

    str[len] = '\0';
    printf(" orginial: %s\n", str);
    t = 0;
    front = -1;

    for (int i = 0; i < len;)
    {
        symbol = str[i];
        switch (symbol)
        {
        case '+':
        case '-':
            while (front >= 0 && stack[front] != '(')
            {
                ex[t] = stack[front];
                front--;
                t++;
            }
            front++;
            stack[front] = symbol;
            i++;
            break;

        case '*':
        case '/':
            while (stack[front] == '*' || stack[front] == '/' || stack[front] == '^')
            {
                ex[t] = stack[front];
                front--;
                t++;
            }
            front++;
            stack[front] = symbol;
            i++;
            break;

        case '^':
            while (stack[front] == '^')
            {
                ex[t] = stack[front];
                front--;
                t++;
            }
            front++;
            stack[front] = symbol;
            i++;
            break;

        case '(':
            front++;
            stack[front] = symbol;
            i++;
            break;

        case ')':
            while (stack[front] != '(' && front >= 0)
            {
                ex[t] = stack[front];
                front--;
                t++;
            }
            front--;
            i++;
            break;

        default: 
            int flag = false;
            while (symbol == '@' || (symbol >= '0' && symbol <= '9') || symbol == '.')
            {
                if (symbol == '@')
                {
                    flag = true;
                    i++;
                    symbol = str[i];
                    continue;
                }
                ex[t] = symbol;
                t++; 
                i++; 
                symbol = str[i];
            }
            if (flag)
            {
                ex[t] = '@';
                t++;
            }
            ex[t] = '&';
            t++;
            break;
        }
    }

    while (front >= 0)
    {
        ex[t] = stack[front];
        t++;
        front--;
    }

    ex[t] = '\0';
    printf(" Reverse Polish: %s\n", ex);
    len = t;
    printf(" Sum: %f\n", calc());
}