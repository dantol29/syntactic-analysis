#include <vector>
#include <string>
#include <iostream>

enum control
{
    LEFT,
    RIGHT,
    FRONTKICK,
    FRONTPUNCH,
    BACKPUNCH,
    BLOCK
};

typedef struct state
{
    std::vector<std::pair<control, int>> transitions;
    std::string output;
} t_state;

typedef std::pair<std::vector<control>, std::string> rule;

std::string control_to_string(const control &c)
{
    switch (c)
    {
    case LEFT:
        return "Left";
    case RIGHT:
        return "Right";
    case FRONTKICK:
        return "FrontKick";
    case FRONTPUNCH:
        return "FrontPunch";
    case BACKPUNCH:
        return "BackPunch";
    case BLOCK:
        return "Block";
    }
}

void print_states(std::vector<t_state> &states)
{
    int i = 0;
    for (auto state = states.begin(); state != states.end(); state++, i++)
    {
        std::cout << "\n\nState: " << i << std::endl;
        for (auto transition = state->transitions.begin(); transition != state->transitions.end(); transition++)
        {
            std::cout << control_to_string(transition->first) << " -> " << transition->second << std::endl;
        }

        if (!state->output.empty())
            std::cout << "Output: " << state->output << std::endl;
    }
}

void create_rules(std::vector<rule> &rules)
{
    std::vector<control> controls = {LEFT, RIGHT, FRONTPUNCH};
    rules.push_back(std::make_pair(controls, "Fireball"));

    controls = {LEFT, RIGHT, FRONTKICK};
    rules.push_back(std::make_pair(controls, "Shadow Kick"));

    controls = {RIGHT, RIGHT, RIGHT, BACKPUNCH};
    rules.push_back(std::make_pair(controls, "Finisher"));

    controls = {BLOCK, FRONTPUNCH};
    rules.push_back(std::make_pair(controls, "Low Blow"));
}

int get_transition(const control c, const state &s)
{
    for (auto transition = s.transitions.begin(); transition != s.transitions.end(); transition++)
        if (transition->first == c)
            return transition->second;

    return -1;
}

int main()
{
    std::vector<t_state> states;
    std::vector<rule> rules;

    create_rules(rules);

    // initial empty state
    states.push_back({});

    for (auto r = rules.begin(); r != rules.end(); r++)
    {
        int current_state = 0;
        for (auto input = r->first.begin(); input != r->first.end(); input++)
        {
            int transition = get_transition(*input, states[current_state]);
            if (transition == -1)
            {
                int new_state_index = states.size();
                states[current_state].transitions.push_back(std::make_pair(*input, new_state_index));
                // create new empty state
                states.push_back({});

                transition = new_state_index;
            }

            current_state = transition;
        }

        states[current_state].output = r->second;
    }

    print_states(states);
}
