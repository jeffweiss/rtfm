Design
------

The high-level design should look something like the block diagram below:

```
          [facts]
client   --------->   queue
 
                        |
                        | [payload]
                        |
                        v 

                    processor  -------->  DB

                        |
                        | [notification w/ facts]
                        |
                        V

                      topic

                        |
                        | [payload]
                        |
                        V

                    visualizer

```

A client machine will gather its facts. These facts will be attached to a message,
along with a timestamp, and submitted to a queue for processing.

Processors will retrieve messages from the queue and add them to the database.
We have a couple simple considerations:

 * each message on the queue should represent a unique point in time for the facts
 * if a message is processed twice, the later entry wins
 * messages can be processed out of order because they should be unique events

Upon completion of writing the facts to the database, the processor will publish
a `WriteComplete` event to a topic. The payload of that event should include the
original facts along with some processing metadata and statistics.

A visualizer will subscribe to the topic for the `WriteComplete` events and 
incorporate the latest set of facts (included in the event payload) into its
visualization, indexed by original timestamp.
