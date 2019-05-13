source('utils.m');global  SGD;global  ADAM;global  ADAPTIVE_ETA;[SGD, ADAM, ADAPTIVE_ETA] = enum();function [eta_correction, momentum] = eta_optimization()    global NeuralNet;    alfa = NeuralNet.alfa;    beta = NeuralNet.beta;    eta = NeuralNet.eta;    momentum = NeuralNet.momentum;    delta_error = NeuralNet.adaptive_eta_error;    error_horizon = NeuralNet.error_horizon;    error_vec_size = size(delta_error)(2);    if( error_horizon >= error_vec_size)      error_horizon = error_vec_size - 1;    endif    error_horizon = error_vec_size - error_horizon;    delta_error = (delta_error(error_horizon:end));    if(size(delta_error)(2) > 2)      delta_error_beta = delta_error(end) - delta_error(end -1);    else      delta_error_beta = 0;    end    delta_between_steps = delta_error(:, 1:end-1);    delta_between_steps = [0, delta_between_steps];    delta_error =  mean(sign(delta_error - delta_between_steps));        %printf("delta_error ----> %f\n", delta_error);    if(delta_error < 0)      eta_correction = alfa;      momentum = NeuralNet.original_momentum;    elseif(delta_error_beta > 0)      eta_correction =  -beta * eta;      momentum = 0;      #NeuralNet.adaptive_eta_error(end) = NeuralNet.adaptive_eta_error(end -1);    else      eta_correction = 0;     endif     endfunctionfunction [eta_correction, w_correction, b_correction ] = weight_correction(w_vector, b_vector, a_vector, deltas, prev_derivatives, prev_bias_derivatives)  global NeuralNet;  eta = NeuralNet.eta;  momentum = NeuralNet.momentum;  weight_decay = NeuralNet.weight_decay;  eta_correction = 0;    global  SGD;  global  ADAM;  global  ADAPTIVE_ETA;    switch(NeuralNet.optimization)    case(SGD)      w_correction = eta * (a_vector') * deltas + momentum * prev_derivatives - eta * weight_decay * w_vector;       b_correction = eta * sum(deltas) + momentum * prev_bias_derivatives - eta * weight_decay * b_vector;    case(ADAM)      momentum = NeuralNet.adam_weight_first_momentum;      variance = NeuralNet.adam_weight_second_momentum;      gradient = (a_vector') * deltas;      momentum = NeuralNet.beta_1 * momentum + (1 - NeuralNet.beta_1) * gradient;      variance = NeuralNet.beta_2 * variance + (1 - NeuralNet.beta_2) * (gradient .* gradient);      momentum_bias_corrected = momentum ./ (1 - NeuralNet.beta_1 ^ NeuralNet.epoch);      variance_bias_corrected = variance ./ (1 - NeuralNet.beta_2 ^ NeuralNet.epoch);            w_correction = eta * ( momentum_bias_corrected ./ (sqrt(variance_bias_corrected) +NeuralNet.adam_epsilon));      % Update network momentums for weights      NeuralNet.adam_first_momentum = momentum;      NeuralNet.adam_second_momentum = variance;      % Now for the bias vector      momentum = NeuralNet.adam_bias_first_momentum;      variance = NeuralNet.adam_bias_second_momentum;      % Bias gradient      gradient = sum(deltas);      bias_momentum = NeuralNet.beta_1 * momentum + (1 - NeuralNet.beta_1) * gradient;      bias_variance = NeuralNet.beta_2 * variance + (1 - NeuralNet.beta_2) * (gradient .* gradient);      momentum_bias_corrected = momentum / (1 - NeuralNet.beta_1 ^ NeuralNet.epoch);      variance_bias_corrected = variance / (1 - NeuralNet.beta_2 ^ NeuralNet.epoch);      b_correction = eta * ( momentum_bias_corrected ./ (sqrt(variance_bias_corrected) + NeuralNet.adam_epsilon));      % Update network bias momentums      NeuralNet.adam_bias_first_momentum = momentum;      NeuralNet.adam_bias_second_momentum = variance;    case(ADAPTIVE_ETA)      [eta_correction, momentum] = eta_optimization();      eta += eta_correction;      eta = ifelse(eta <= 0, NeuralNet.original_eta, eta);      w_correction = eta * (a_vector') * deltas + momentum * prev_derivatives - eta * weight_decay * w_vector;       b_correction = eta * sum(deltas) + momentum * prev_bias_derivatives - eta * weight_decay * b_vector;    otherwise      printf("wrong optimization\n");  endswitch     NeuralNet.momentum = momentum;  endfunction