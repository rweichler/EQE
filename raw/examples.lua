-- Example functions for raw audio manipulation.
-- In order to use these, run the command `eqe raw`,
-- and then run `eqe.lua = examples.noise`, or whatever.
-- If you wanna set it back to normal do `eqe.lua = nil`.

local examples = {}

function examples.noise(audio, num_samples, num_channels, sample_rate)
    for i=0,num_samples-1 do
        for c=0,num_channels-1 do
            audio[c][i] = math.random() - 0.5
        end
    end
end

return examples
