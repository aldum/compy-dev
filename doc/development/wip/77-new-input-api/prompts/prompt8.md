Rule to memoize: in signature `$dirname/$filename<N>.md`, N is calculated once per round as
``` bash
#!/bin/bash
echo $((  $(ls "${dirname}/${filename}*.md" | wc -l) + 1 ))
```


Read `./prompts/prompt<N-1>.md` (the last updated file under ./prompts/) to understand the current context and rules, but do not follow it literally.

Now you're at next iteration.
Specifications were presented to stakeholders and we got a feedback (check git diff or last git commit to see).

Can you update the whole chain unambiguously without my direction/resolution ? 
Write your conclusions into `./reevaluations/round<N>.md` and if you update anything, write the changelog as  `./reevaluation/changes<N>.md `

And tell me where we are
