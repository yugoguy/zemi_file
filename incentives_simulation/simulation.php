<?php

function discretize_total_contribution($total_contribution, $num_states, $N, $E) {
    $max_total = $N * $E;
    $state = round(($total_contribution / $max_total) * ($num_states - 1));
    $state = min($state, $num_states - 1);
    return intval($state);
}

class Agent {
    public $Q;
    public $temperature;
    public $num_actions;
    public $lr;
    public $num_states;
    public $state_counts;
    public $state_frequencies;

    public function __construct($num_states, $num_actions, $temperature, $lr, $endowment, $MPCR, $incentive) {
        $actions = $this->linspace(0, $endowment, $num_actions);
        $this->Q = array();
        for ($i = 0; $i < $num_states; $i++) {
            $q_row = array();
            foreach ($actions as $action) {
                $mean = $endowment - $action + ($MPCR * (1 + $incentive)) * $action;
                $std = ($endowment - $action + ($MPCR) * $action) * $temperature / 100;
                $value = $this->random_normal($mean, $std);
                $q_row[] = $value;
            }
            $this->Q[] = $q_row;
        }
        $this->temperature = $temperature;  
        $this->num_actions = $num_actions;
        $this->lr = $lr;
        $this->num_states = $num_states;
        $this->state_counts = array_fill(0, $num_states, $temperature);
        $sum_state_counts = array_sum($this->state_counts);
        $this->state_frequencies = array();
        foreach ($this->state_counts as $count) {
            $this->state_frequencies[] = $count / $sum_state_counts;
        }
    }

    private function linspace($start, $end, $num) {
        $arr = array();
        if ($num == 1) {
            $arr[] = $start;
        } else {
            $step = ($end - $start) / ($num - 1);
            for ($i = 0; $i < $num; $i++) {
                $arr[] = $start + $i * $step;
            }
        }
        return $arr;
    }

    private function random_normal($mean, $std_dev) {
        $u1 = mt_rand() / mt_getrandmax();
        $u2 = mt_rand() / mt_getrandmax();
        $z0 = sqrt(-2.0 * log($u1)) * cos(2.0 * M_PI * $u2);
        return $z0 * $std_dev + $mean;
    }

    public function update_state_counts($observed_state) {
        $this->state_counts[$observed_state] += 1;
        $sum_state_counts = array_sum($this->state_counts);
        $this->state_frequencies = array();
        foreach ($this->state_counts as $count) {
            $this->state_frequencies[] = $count / $sum_state_counts;
        }
    }

    public function predict_state() {
        $predicted_state = $this->random_choice_weighted(range(0, $this->num_states - 1), $this->state_frequencies);
        return $predicted_state;
    }

    private function random_choice_weighted($values, $weights) {
        $total = array_sum($weights);
        $rand = mt_rand() / mt_getrandmax() * $total;
        $cum_sum = 0;
        foreach ($values as $i => $value) {
            $cum_sum += $weights[$i];
            if ($rand <= $cum_sum) {
                return $value;
            }
        }
        return $values[count($values) - 1];
    }

    public function softmax($q_values) {
        if ($this->temperature > 0) {
            $max_q = max($q_values);
            $exp_q = array();
            foreach ($q_values as $q) {
                $exp_q[] = exp(($q - $max_q) / $this->temperature);
            }
            $sum_exp_q = array_sum($exp_q);
            $probabilities = array();
            foreach ($exp_q as $value) {
                $probabilities[] = $value / $sum_exp_q;
            }
        } else {
            $probabilities = array_fill(0, count($q_values), 0.0);
            $max_index = array_search(max($q_values), $q_values);
            $probabilities[$max_index] = 1.0;
        }
        return $probabilities;
    }

    public function choose_action($use_most_likely_state = false) {
        if ($use_most_likely_state) {
            $max_value = max($this->state_frequencies);
            $predicted_state = array_search($max_value, $this->state_frequencies);
        } else {
            $predicted_state = $this->predict_state();
        }
        $q_values = $this->Q[$predicted_state];
        $probabilities = $this->softmax($q_values);
        $action = $this->random_choice_weighted(range(0, count($q_values) - 1), $probabilities);
        return array($action, $predicted_state);
    }

    public function update_Q($state, $action, $reward) {
        $this->Q[$state][$action] = $this->lr * $reward + (1 - $this->lr) * $this->Q[$state][$action];
    }
}

class Environment {
    public $N;
    public $E;
    public $MR;
    public $num_rounds;
    public $initial_temperature;
    public $lr;
    public $num_states;
    public $num_actions;
    public $incentive;
    public $agents;
    public $action_values;
    public $result;
    public $record;

    public function __construct($N, $E, $MR, $num_rounds, $temperature=10, $lr=0.5, $num_states=11, $num_actions=11, $incentive=0) {
        $this->N = $N;                  
        $this->E = $E;                
        $this->MR = $MR;            
        $this->num_rounds = $num_rounds;
        $this->initial_temperature = $temperature;
        $this->lr = $lr;
        $this->num_states = $num_states;
        $this->num_actions = $num_actions;
        $this->incentive = $incentive; 
        $this->agents = array();
        for ($i = 0; $i < $N; $i++) {
            $this->agents[] = new Agent($this->num_states, $this->num_actions, $this->initial_temperature, $this->lr, $this->E, $this->MR / $this->N, $this->incentive);
        }
        $this->action_values = $this->linspace(0, $this->E, $this->num_actions);
    }

    private function linspace($start, $end, $num) {
        $arr = array();
        if ($num == 1) {
            $arr[] = $start;
        } else {
            $step = ($end - $start) / ($num - 1);
            for ($i = 0; $i < $num; $i++) {
                $arr[] = $start + $i * $step;
            }
        }
        return $arr;
    }

    public function run_simulation() {
        $total_contributions_over_time = array();
        $prev_total_contribution = 0;
        $prev_state = discretize_total_contribution($prev_total_contribution, $this->num_states, $this->N, $this->E);

        for ($round_num = 0; $round_num < $this->num_rounds; $round_num++) {
            $contributions = array();
            $actions = array();
            $predicted_states = array();

            foreach ($this->agents as $agent) {
                list($action, $predicted_state) = $agent->choose_action();
                $contribution = $this->action_values[$action];
                $contributions[] = $contribution;
                $actions[] = $action;
                $predicted_states[] = $predicted_state;
            }

            $total_contribution = array_sum($contributions);
            $total_contributions_over_time[] = $total_contribution;

            $payoff_per_agent = ($this->MR * (1 + $this->incentive) * $total_contribution) / $this->N;
            $payoffs = array();
            foreach ($contributions as $contrib) {
                $payoffs[] = $this->E - $contrib + $payoff_per_agent;
            }

            $prev_state = discretize_total_contribution($total_contribution, $this->num_states, $this->N, $this->E);

            for ($i = 0; $i < count($this->agents); $i++) {
                $reward = $payoffs[$i];
                $this->agents[$i]->update_Q($predicted_states[$i], $actions[$i], $reward);
                $this->agents[$i]->update_state_counts($prev_state);
            }
        }

        $final_contributions = array();
        $final_rounds = 1;
        foreach ($this->agents as $agent) {
            $agent->temperature = 0;
        }

        for ($round_num = 0; $round_num < $final_rounds; $round_num++) {
            $contributions = array();
            $actions = array();
            $predicted_states = array();

            foreach ($this->agents as $agent) {
                list($action, $predicted_state) = $agent->choose_action(true);
                $contribution = $this->action_values[$action];
                $contributions[] = $contribution;
                $actions[] = $action;
                $predicted_states[] = $predicted_state;
            }

            $total_contribution = array_sum($contributions);
            $total_contributions_over_time[] = $total_contribution;
            $final_contributions[] = $total_contribution;

            $payoff_per_agent = ($this->MR * (1 + $this->incentive) * $total_contribution) / $this->N;
            $payoffs = array();
            foreach ($contributions as $contrib) {
                $payoffs[] = $this->E - $contrib + $payoff_per_agent;
            }

            $prev_state = discretize_total_contribution($total_contribution, $this->num_states, $this->N, $this->E);

            for ($i = 0; $i < count($this->agents); $i++) {
                $reward = $payoffs[$i];
                $this->agents[$i]->update_Q($predicted_states[$i], $actions[$i], $reward);
                $this->agents[$i]->update_state_counts($prev_state);
            }
        }

        $average_final_contribution = array_sum($final_contributions) / count($final_contributions);
        $this->result = $average_final_contribution;
        $this->record = $total_contributions_over_time;
    }
}

// Handle AJAX request
if (isset($_POST['ajax'])) {
    // Include the classes and functions
    // (The classes are already included above)
    // Get the incentive value from POST data
    $incentive = floatval($_POST['incentive']);

    // Set simulation parameters
    $N = 10;
    $E = 100;
    $MR = 5;
    $num_rounds = 1000;
    $temperature = 10;
    $lr = 1;
    $num_states = 11;
    $num_actions = 11;

    // Run the simulation
    $env = new Environment($N, $E, $MR, $num_rounds, $temperature, $lr, $num_states, $num_actions, $incentive);
    $env->run_simulation();

    // Prepare the response data
    $response = array(
        'average_final_contribution' => $env->result,
        'record' => $env->record
    );

    // Return the response as JSON
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

?>
