# godot-journey

This project is my attempt to create an Articy: Draft / Twine / YarnSpinner-like experience for Godot Engine 3.x.

For an updated list of the proposed features, see the [Core API Overview](https://github.com/willnationsdev/godot-journey/issues/1).

The features these systems provide include a narrative database, a level planner, an interactive dialog system that has access to both of the previous elements, and a nestable graph-based overview of the scenes in your narrative.

The intended roadmap for THIS plugin involves the consolidation of 3 or 4 independent plugins:

The first plugin is for a backend, generic, narrative database...
- Initially provided templates might include:
    - Character
    - Life (plants, wildlife)
    - Place (things where concepts can BE)
    - Object (non-living thing)
    - Idea (abstract thing: Lore, History, Philosophy, Knowledge, etc.)
- Users could define templates in the form of script files with exported properties.
- Setting a script onto a Resource object which stores the data allows you to easily define new templates / edit existing templates for a given concept.
- These Resource objects could then be serialized in one of two ways, depending on the version of the plugin installed:
    - Users could opt for a `.res`/`.tres`-based local storage. Simplest, fastest, most intuitive.
    - Users could opt for Neo4j Graph Database storage. The plugin would ideally come with some standalone version of the database so that C# drivers could access it. In this scenario (if it's doable), Resource objects would be serialized into Neo4j nodes.
        - The advantage of this option is that you get MUCH more sophisticated querying capability with the Cypher query language, essential for large projects.
        - I even have thoughts about composing Cypher queries using a scene file since GraphNodes and their connections can be used to represent an actual Cypher query.
- Regardless of which method is used, the plugin would include a graph-based editor for this content that mirrors Neo4j systems:
    - Every created concept appears as a node (GraphNode). Every concept has a script attached detailing its available properties.
    - Users could click on any GraphNode to see the properties associated with the type in the Inspector.
        - We could also (POSSIBLY) implement functionality to expand/collapse the GraphNode with the properties in-lined rather than having to view them in the Inspector, but that'd be a lower priority.
    - Relationships can be created between nodes. Every relationship must have one and only one label. They may also have any number of properties.
        - Neo4j natively supports Relationships, but in the .res version, you'd probably have to store each relationship type as its own dictionary in a singular .res file for all relationships, e.g. one dictionary for lives_with relationships mapping one node to another node, etc..

With this database accessible, you could then have another plugin for a graph-based story editor.
- users could then do screenwriting using an interface akin to Twine or Yarn.
    - The user is presented with a graph in which they can create Passage nodes.
    - Every Passage includes a TextEdit for a narrative scripting language (similar to Harlowe or SugarCube in Twine).
        - I'd want to add word-wrap support to the TextEdit node for this.
        - I'd want the scripting language to...
            - Have lines starting with `@character_name: dialogue text`
            - Lines without a speaker-identifier (`: dialogue text`) would be judged as simply having no speaker.
            - Programmers could define accompanying visual/audio data references based on the speaker.
            - Allow `@character_name(...): dialogue text` to let users provide parameters for manners of speech, directed speech, etc., trigger voice cues, animations, etc. (user-defined).
            - Allow users to inline GDScript code to be called before/during/after the dialogue is triggered.
            - Allow users to inline logic testing, variable assignment, and flow control (perhaps via macros?) to modify which text is displayed.
            - Allow users to define their own custom macros bound to custom GDScript functions.
            - (Example at the bottom):
    - Groups of Passages are organized into Sequences (`GraphEdit`s) which can be figuratively nested into each other
        - A project will have one StoryScript singleton.
        - A StoryScript will have 0 or more Stories which establish a shared source of information about a story.
        - A StoryScript will have 0 or more Sequences which each rely on one Story (often the same).
        - Sequences are broken down into sub-Sequences (they can figuratively be instanced within each other).
        - ^ note that GraphEdits cannot be nested within each other which is why we ultimately keep all Sequences / sub-Sequences as unique children of the Story under the StoryScript singleton. No ACTUAL instancing within each other occurs.
        - Sequences ultimately break down into Passages, the GraphNodes for story content.
        - Users will be able to refer to Sequences in the Scene dock.
        - A dedicated node for Passage and another dedicated node for PackedSequence will exist where the Sequence simply simulates a singular GraphNode with all the inputs and outputs of an entire Sequence GraphEdit.
        - If you "open" a PackedSequence node, it switches you over to the appropriate Sequence GraphEdit (similar to how nested scenes work).
    - A StoryScript singleton could be used to manage data for the story and interact with Sequences.
        - Discrete pieces of StoryScript are executed in their entirety by calls to an `advance()` function in the StoryScript singleton.
        - Sequences of pieces can therefore be animated by the AnimationPlayer when animating calls to the function.
    - I'm THINKING I might be able to try and retrofit the gdscript module to create some sort of StoryScript module similarly. That way you can still in-line GDScript in some way.
    - StoryScript would ultimately need to be able to compile into a data format, possibly a variation of .twee or use JSON, so that people can use a text editor to view the entirety of a story.

Since all of this gives us a database of content (1 of 2 plugins) and a micro-level story editor (another plugin), we therefore need a macro-level quest editor to connect it all to data-based objectives.

- Content in the game is defined by `Task` objects. You can make user-defined `Task`s.
- Users can add `Task`s as prerequisites or as objectives for a Quest.
    - users could then tie in task\_completed or quest\_completed signals into StoryScript Sequence activations.
- Quests of this sort would be developed within VisualScript probably, and there'd need to be a GDScript variant for text-based development (if it is desired).

These 4 plugins in total form the consolidated Quest editing tool

StoryScript example:

                                                    # Note that any set of 4 consecutive spaces are replaced with tabs and all tabs are removed prior to interpretation 
    # Bob and Sam are sitting on a couch at home.   # a one-line comment
    @Bob:                                           # a persona identifier. It refers to a node that is the child of the StoryScript singleton
        I really wish I had a cheeseburger.         # visible text dialogue.
    <% #inlined GDScript                            # non-visible GDScript code to execute
        Story.wants_cheeseburger = true             # variable setting
        Story.drink = "Dr. Pepper"                  # ^
    %>                                              # ending tag
                                                    # an empty line indicates termination of a discrete unit of dialogue. The text as it will appear on screen in a dialogue box is now: "I really wish I had a cheeseburger."
    Honestly, if I couldn't eat                     # another visible line
    <<if Story.wants_cheeseburger>>                 # flow control via macros
        cheeseburgers                               # text to appear if true
    <<else>>                                        # 
        hot dogs                                    # text to appear if false
    <<endif>>,                                      # termination of for loop and a visible comma
    <<br>>                                          # a marker indicating a visible line break in the text box
    I don't know what I'd do with myself.           # this text shows up on a second line

    At the very least, I'd need some
    << echo Story.drink >>.                         # this text inserts "Dr. Pepper" into the text

    @Sam(expr="confused"):                          # can define options (key/value pairs) to customize how a line is delivered.
        Seriously? That's all you can think about right now?

        What about the
        <<list Story.fridge.foot <{delay 0.5}>>>    # a custom macro written by users. It executes the same output as the below, commented code
        <#                                          # a start comment tag for macros
        <<for a_food in Story.fridge.food>>         # for loop
            <<delay 0.5>>                           # delays the displaying of the following text output. Directly inserted parameter for macro-powered macros
            <<if a_food == Story.fridge.food.back()>>
                , and
            <<elif a_food != Story.fridge.food.front()>>
                ,
            <<endif>>
            <<echo a_food>>
        <<endfor>>
        #>                                          # an end comment tag for macros
        that we already have...

    @Sam(expr="serious"):                           # these lines happen at the same time because there is no newline separating them
        in the FRIDGE?
    @Bob(expr="annoyed", voice="mocking"):
        in the FRIDGE.

    @Bob(voice="default"):                          # expression is still "annoyed", carries over.
        Yeah, I know.<<br>>I just don't like that stuff.

        There's just too much [green stuff](green_stuff). # Creates a link from this Passage to the Passage with the title "green_stuff".
                                                            # ^ The text shows up as a hyperlink to click, at which point the Passage is triggered.
                                                            # ^ Multiple Passages can be triggered at the same time (allowing for simultaneous conversations).
    # It should also be possible to attach Passages to signals so that emitting the signal triggers the Passage.
    # StoryScript should be able to query and reference the narrative database, ideally with auto-completion provided.
